# frozen_string_literal: true

GITHUB_API_PATH = 'https://api.github.com'
TEMP_GIT_CLONES_PATH = 'tmp/git_clones'

class CheckRepositoryJob < ApplicationJob
  queue_as :default

  def perform(check)
    @check = check
    repository = check.repository
    @temp_repo_path = "#{TEMP_GIT_CLONES_PATH}/#{repository.name}/"
    @language_class = LintersAndParsers.const_get(repository.language.upcase_first)

    perform_fetch

    json_string = perform_check

    perform_parse(json_string)

    # Сохраняем все изменения перед финализацией
    check.save!

    # Убеждаемся, что passed установлен правильно перед финализацией
    # Используем reload чтобы убедиться, что мы работаем с актуальными данными
    check.reload
    violations_count = check.number_of_violations.to_i
    check.passed = violations_count.zero?
    
    Rails.logger.debug { "Before finish: violations=#{violations_count}, passed=#{check.passed}" }
    
    check.save!
    check.mark_as_finished!
    
    # Проверяем финальное состояние после mark_as_finished
    check.reload
    Rails.logger.debug { "After finish: violations=#{check.number_of_violations}, passed=#{check.passed}, state=#{check.aasm_state}" }
    
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
    json_string = lint_check.call(@temp_repo_path, @language_class)
    @check.mark_as_checked!
    json_string
  rescue StandardError => e
    Rails.logger.debug { "Check error: #{e.message}" }
    raise e
  end

  def perform_parse(json_string)
    @check.parse!
    parse_check = ApplicationContainer[:parse_check]
    check_results, number_of_violations = parse_check.call(@temp_repo_path, @language_class, json_string)
    
    # Убеждаемся, что check_results - это массив
    @check.check_results = check_results.is_a?(Array) ? check_results : []
    
    # Убеждаемся, что number_of_violations - это число
    violations_count = number_of_violations.to_i
    @check.number_of_violations = violations_count
    
    # Устанавливаем passed в зависимости от количества нарушений
    @check.passed = violations_count.zero?
    
    Rails.logger.debug { "Parse completed: violations=#{@check.number_of_violations}, passed=#{@check.passed}, results_count=#{@check.check_results.size}" }
    
    @check.mark_as_parsed!
  rescue StandardError => e
    Rails.logger.debug { "Parse error: #{e.message}" }
    Rails.logger.debug { e.backtrace.first(5).join("\n") }
    raise e
  end
end
