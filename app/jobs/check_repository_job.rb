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

    check.save!

    check.mark_as_finished!
    UserMailer.with(check:).repo_check_verification_failed.deliver_later unless check.passed
  rescue StandardError => e
    check.mark_as_failed!
    UserMailer.with(check:).repo_check_failed.deliver_later

    Rails.logger.debug e
    Rollbar.error e
  ensure
    run_programm "rm -rf #{@temp_repo_path}"
  end

  private

  def perform_fetch
    @check.fetch!
    fetch_repo_data = ApplicationContainer[:fetch_repo_data]
    @check.commit_id = fetch_repo_data.call(@check.repository, @temp_repo_path)
    @check.mark_as_fetched!
  end

  def perform_check
    @check.check!
    lint_check = ApplicationContainer[:lint_check]
    json_string = lint_check.call(@temp_repo_path, @language_class)
    @check.mark_as_checked!
    json_string
  end

  def perform_parse(json_string)
    @check.parse!
    @check.check_results, number_of_violations = parse_check(@temp_repo_path, @language_class, json_string)
    @check.number_of_violations = number_of_violations
    @check.passed = number_of_violations.zero?
    @check.mark_as_parsed!
  end
end

def fetch_repo_data(repository, temp_repo_path)
  run_programm "rm -rf #{temp_repo_path}"

  _, exit_status = run_programm "git clone #{repository.link}.git #{temp_repo_path}"
  raise StandardError unless exit_status.zero?

  last_commit = HTTParty.get("#{GITHUB_API_PATH}/repos/#{repository.full_name}/commits").first
  last_commit['sha'][...7]
end

def lint_check(temp_repo_path, language_class)
  language_class.linter(temp_repo_path) # json_string
end

def parse_check(temp_repo_path, language_class, json_string)
  language_class.parser(temp_repo_path, json_string) # [check_results, number_of_violations]
end

def run_programm(command)
  stdout, exit_status = Open3.popen3(command) do |_stdin, stdout, _stderr, wait_thr|
    [stdout.read, wait_thr.value]
  end
  # pp stdout # вывод stdout
  # pp exit_status.exitstatus # https://docs.ruby-lang.org/en/2.0.0/Process/Status.html#method-i-exitstatus
  [stdout, exit_status.exitstatus]
end
