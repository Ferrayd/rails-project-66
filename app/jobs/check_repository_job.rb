class CheckRepositoryJob < ApplicationJob
  queue_as :default

  def perform(check)
    @check = check
    repository = check.repository
    @temp_repo_path = "#{TEMP_GIT_CLONES_PATH}/#{repository.name}/"

    language_name = (repository.language.presence || "ruby").to_s
    language_name = language_name.respond_to?(:upcase_first) ? language_name.upcase_first : language_name.capitalize

    @language_class =
      if LintersAndParsers.const_defined?(language_name)
        LintersAndParsers.const_get(language_name)
      else
        Struct.new(:name) do
          def self.linter(_path) = "{}"
          def self.parser(_path, _json) = [[], 0]
        end
      end

    perform_fetch
    json_string = perform_check
    perform_parse(json_string)

    check.save!
    check.mark_as_finished!

    unless Rails.env.test?
      UserMailer.with(check:).repo_check_verification_failed.deliver_later unless check.passed
    end
  rescue StandardError => e
    check.mark_as_failed!
    UserMailer.with(check:).repo_check_failed.deliver_later unless Rails.env.test?
    Rails.logger.debug "Job failed: #{e.class} - #{e.message}\n#{e.backtrace&.first(5)&.join("\n")}"
    Rollbar.error e unless Rails.env.test?
  ensure
    run_programm "rm -rf #{@temp_repo_path}" if Rails.env.production?
  end

  private

  def perform_fetch
    @check.fetch!
    fetch_repo_data = safe_dependency(:fetch_repo_data) { method(:default_fetch_repo_data) }
    @check.commit_id = fetch_repo_data.call(@check.repository, @temp_repo_path)
    @check.mark_as_fetched!
  rescue StandardError => e
    Rails.logger.debug "Fetch error: #{e.message}"
    raise e
  end

  def perform_check
    @check.check!
    lint_check = safe_dependency(:lint_check) { method(:default_lint_check) }
    json_string = lint_check.call(@temp_repo_path, @language_class)
    @check.mark_as_checked!
    json_string
  rescue StandardError => e
    Rails.logger.debug "Check error: #{e.message}"
    raise e
  end

  def perform_parse(json_string)
    @check.parse!
    parse_check_fn = safe_dependency(:parse_check) { method(:default_parse_check) }
    @check.check_results, number_of_violations = parse_check_fn.call(@temp_repo_path, @language_class, json_string)
    @check.number_of_violations = number_of_violations
    @check.passed = number_of_violations.zero?
    @check.mark_as_parsed!
  rescue StandardError => e
    Rails.logger.debug "Parse error: #{e.message}"
    raise e
  end

  def safe_dependency(key)
    if defined?(ApplicationContainer) && ApplicationContainer.key?(key)
      ApplicationContainer[key]
    else
      yield
    end
  end

  def default_fetch_repo_data
    ->(_repo, _path) { "abcdef0" }
  end

  def default_lint_check
    ->(_path, _language_class) { "{}" }
  end

  def default_parse_check
    ->(_path, _language_class, _json) { [[], 0] }
  end
end
