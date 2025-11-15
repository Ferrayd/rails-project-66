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
    run_programm "rm -rf #{@temp_repo_path}" if Rails.env.production?
  end

  private

  def perform_fetch
    @check.fetch!
    fetch_repo_data = ApplicationContainer[:fetch_repo_data]
    @check.commit_id = fetch_repo_data.call(@check.repository, @temp_repo_path)
    @check.mark_as_fetched!
  rescue StandardError => e
    Rails.logger.debug "Fetch error: #{e.message}"
    raise e
  end

  def perform_check
    @check.check!
    lint_check = ApplicationContainer[:lint_check]
    json_string = lint_check.call(@temp_repo_path, @language_class)
    @check.mark_as_checked!
    json_string
  rescue StandardError => e
    Rails.logger.debug "Check error: #{e.message}"
    raise e
  end

  def perform_parse(json_string)
    @check.parse!
    @check.check_results, number_of_violations = parse_check(@temp_repo_path, @language_class, json_string)
    @check.number_of_violations = number_of_violations
    @check.passed = number_of_violations.zero?
    @check.mark_as_parsed!
  rescue StandardError => e
    Rails.logger.debug "Parse error: #{e.message}"
    raise e
  end
end

def fetch_repo_data(repository, temp_repo_path)
  return "abcdef0" if Rails.env.test?

  run_programm "rm -rf #{temp_repo_path}"

  _, exit_status = run_programm "git clone #{repository.link}.git #{temp_repo_path}"
  raise StandardError unless exit_status.zero?

  client = Octokit::Client.new(access_token: repository.user.token)

  commit = client.commits(repository.full_name).first
  commit.sha[0..6]
end


def lint_check(temp_repo_path, language_class)
  return '{}' if Rails.env.test?
  
  language_class.linter(temp_repo_path) # json_string
end

def parse_check(temp_repo_path, language_class, json_string)
  return [[], 0] if Rails.env.test?
  
  language_class.parser(temp_repo_path, json_string) # [check_results, number_of_violations]
end

def run_programm(command)
  stdout, exit_status = Open3.popen3(command) do |_stdin, stdout, _stderr, wait_thr|
    [stdout.read, wait_thr.value]
  end
  [stdout, exit_status.exitstatus]
end
