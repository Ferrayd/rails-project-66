# frozen_string_literal: true

GITHUB_API_PATH = 'https://api.github.com'
TEMP_GIT_CLONES_PATH = 'tmp/git_clones'

class CheckRepositoryJob < ApplicationJob
  queue_as :default

  def perform(check)
    @check = check
    repository = check.repository
    
    # Дебаггер: проверяем состояние репозитория
    Rails.logger.debug { "CheckRepositoryJob: repository_id=#{repository.id}, language=#{repository.language.inspect}, name=#{repository.name.inspect}" }
    
    # Защита от nil language
    if repository.language.blank?
      Rails.logger.warn { "CheckRepositoryJob: repository.language is nil for repository_id=#{repository.id}, setting default to 'ruby'" }
      repository.language ||= 'ruby'
      repository.save!
    end
    
    @temp_repo_path = "#{TEMP_GIT_CLONES_PATH}/#{repository.name}/"
    
    # Дебаггер: проверяем значение перед преобразованием
    language_string = repository.language.to_s
    Rails.logger.debug { "CheckRepositoryJob: language_string=#{language_string.inspect}" }
    
    language_class_name = language_string.camelize
    Rails.logger.debug { "CheckRepositoryJob: language_class_name=#{language_class_name.inspect}" }
    
    @language_class = LintersAndParsers.const_get(language_class_name)
    Rails.logger.debug { "CheckRepositoryJob: @language_class=#{@language_class.inspect}" }

    perform_fetch
    json_string = perform_check
    perform_parse(json_string)

    violations_count = check.number_of_violations.to_i
    check.passed = violations_count.zero?
    check.save!
    check.mark_as_finished!

    UserMailer.with(check:).repo_check_verification_failed.deliver_later unless check.passed
  rescue StandardError => e
    check.mark_as_failed!
    UserMailer.with(check:).repo_check_failed.deliver_later
    Rails.logger.debug e
    Rollbar.error e
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
    Rails.logger.debug { "Fetch error: #{e.message}" }
    raise e
  end

  def perform_check
    @check.check!
    lint_check = ApplicationContainer[:lint_check]
    
    # Дебаггер: логируем перед вызовом линтера
    Rails.logger.debug { "CheckRepositoryJob#perform_check: temp_repo_path=#{@temp_repo_path}, language_class=#{@language_class}" }
    
    json_string = lint_check.call(@temp_repo_path, @language_class)
    
    # Дебаггер: логируем результат линтера
    Rails.logger.debug { "CheckRepositoryJob#perform_check: json_string_length=#{json_string&.length || 0}" }
    Rails.logger.debug { "CheckRepositoryJob#perform_check: json_string (first 200 chars): #{json_string&.[](0..200) || 'nil'}" }
    
    @check.mark_as_checked!
    json_string
  rescue StandardError => e
    Rails.logger.debug { "Check error: #{e.message}" }
    Rails.logger.debug { "Check error backtrace: #{e.backtrace.first(5).join("\n")}" }
    raise e
  end

  def perform_parse(json_string)
    @check.parse!
    parse_check = ApplicationContainer[:parse_check]
    check_results, number_of_violations = parse_check.call(@temp_repo_path, @language_class, json_string)

    @check.check_results = check_results.is_a?(Array) ? check_results : []
    violations_count = number_of_violations.to_i
    @check.number_of_violations = violations_count
    @check.passed = violations_count.zero?

    @check.mark_as_parsed!
  rescue StandardError => e
    Rails.logger.debug { "Parse error: #{e.message}" }
    Rails.logger.debug { e.backtrace.first(5).join("\n") }
    raise e
  end
end
