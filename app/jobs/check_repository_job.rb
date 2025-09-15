# frozen_string_literal: true

GITHUB_API_PATH = 'https://api.github.com'
TEMP_GIT_CLONES_PATH = 'tmp/git_clones'

class CheckRepositoryJob < ApplicationJob
  queue_as :default

  def perform(check)
    @check = check
    repository = check.repository
    @temporary_repository_path = "#{TEMP_GIT_CLONES_PATH}/#{repository.name}/"
    @language_parser_class = LintersAndParsers.const_get(repository.language.upcase_first)

    perform_fetch

    linting_results_json = perform_check

    perform_parse(linting_results_json)

    check.save!

    check.mark_as_finished!
    UserMailer.with(check:).repo_check_verification_failed.deliver_later unless check.passed
  rescue StandardError => e
    check.mark_as_failed!
    UserMailer.with(check:).repo_check_failed.deliver_later

    Rails.logger.debug e
    Rollbar.error e
  ensure
    run_program "rm -rf #{@temporary_repository_path}"
  end

  private

  def perform_fetch
    @check.fetch!
    fetch_repository_data = ApplicationContainer[:fetch_repo_data]
    @check.commit_id = fetch_repository_data.call(@check.repository, @temporary_repository_path)
    @check.mark_as_fetched!
  end

  def perform_check
    @check.check!
    lint_checker = ApplicationContainer[:lint_check]
    linting_results_json = lint_checker.call(@temporary_repository_path, @language_parser_class)
    @check.mark_as_checked!
    linting_results_json
  end

  def perform_parse(linting_results_json)
    @check.parse!
    @check.check_results, violations_count = parse_check(@temporary_repository_path, @language_parser_class,
                                                         linting_results_json)
    @check.number_of_violations = violations_count
    @check.passed = violations_count.zero?
    @check.mark_as_parsed!
  end
end

def fetch_repo_data(repository, temporary_repository_path)
  run_program "rm -rf #{temporary_repository_path}"

  _, exit_status = run_program "git clone #{repository.link}.git #{temporary_repository_path}"
  raise StandardError unless exit_status.zero?

  latest_commit = HTTParty.get("#{GITHUB_API_PATH}/repos/#{repository.full_name}/commits").first
  latest_commit['sha'][...7]
end

def lint_check(temporary_repository_path, language_parser_class)
  language_parser_class.linter(temporary_repository_path)
end

def parse_check(temporary_repository_path, language_parser_class, linting_results_json)
  language_parser_class.parser(temporary_repository_path, linting_results_json)
end

def run_program(command)
  stdout_output, exit_status = Open3.popen3(command) do |_stdin, stdout, _stderr, wait_thr|
    [stdout.read, wait_thr.value]
  end
  [stdout_output, exit_status.exitstatus]
end
