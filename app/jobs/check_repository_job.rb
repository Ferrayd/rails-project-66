# frozen_string_literal: true

GITHUB_API_PATH = "https://api.github.com"
TEMP_GIT_CLONES_PATH = "tmp/git_clones"

class CheckRepositoryJob < ApplicationJob
  queue_as :default

  def perform(check)
    @check = check
    repository = check.repository
    @temp_repo_path = "#{TEMP_GIT_CLONES_PATH}/#{repository.name}/"

    language_value = repository.language&.to_s&.upcase_first
    if language_value.present? && LintersAndParsers.const_defined?(language_value)
      @language_class = LintersAndParsers.const_get(language_value)
    else
      @language_class = LintersAndParsers::Ruby
      Rails.logger.debug { "⚠️ Repository language missing or invalid, fallback to Ruby" }
    end

    Rails.logger.debug { "🚀 Starting CheckRepositoryJob for check_id=#{check.id}, language=#{@language_class}" }

    perform_fetch
    json_string = perform_check
    perform_parse(json_string)

    check.save!

    check.mark_as_finished!
    UserMailer.with(check:).repo_check_verification_failed.deliver_later unless check.passed

    Rails.logger.debug { "✅ CheckRepositoryJob finished successfully for check_id=#{check.id}" }
  rescue StandardError => e
    Rails.logger.debug { "❌ CheckRepositoryJob error: #{e.class} - #{e.message}\n#{e.backtrace&.first(3)&.join("\n")}" }

    unless Rails.env.test?
      check.mark_as_failed!
      UserMailer.with(check:).repo_check_failed.deliver_later
    end

    Rollbar.error(e)
  ensure
    run_programm "rm -rf #{@temp_repo_path}" if Rails.env.production?
  end

  private

  def perform_fetch
    @check.fetch!
    fetch_repo_data = ApplicationContainer[:fetch_repo_data]
    @check.commit_id = fetch_repo_data.call(@check.repository, @temp_repo_path)
    @check.mark_as_fetched!
  rescue StandardError => e
    Rails.logger.debug { "⚠️ Fetch error: #{e.message}" }
    raise e
  end

  def perform_check
    @check.check!
    lint_check = ApplicationContainer[:lint_check]
    json_string = lint_check.call(@temp_repo_path, @language_class)

    json_string = "{}" if json_string.blank?
    @check.mark_as_checked!
    json_string
  rescue StandardError => e
    Rails.logger.debug { "⚠️ Lint check error: #{e.message}" }
    raise e
  end

  def perform_parse(json_string)
    @check.parse!
    parse_check = ApplicationContainer[:parse_check]
    @check.check_results, number_of_violations = parse_check.call(@temp_repo_path, @language_class, json_string)

    @check.check_results ||= []
    @check.number_of_violations ||= 0
    @check.passed = @check.number_of_violations.zero?

    @check.mark_as_parsed!
  rescue StandardError => e
    Rails.logger.debug { "⚠️ Parse error: #{e.message}" }
    raise e
  end
end
