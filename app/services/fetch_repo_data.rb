# frozen_string_literal: true

require "httparty"
require "open3"

class FetchRepoData
  GITHUB_API_PATH = "https://api.github.com"

  def call(repository, temporary_repository_path)
    run_program "rm -rf #{temporary_repository_path}"

    _, exit_status = run_program "git clone #{repository.link}.git #{temporary_repository_path}"
    raise StandardError, "Git clone failed" unless exit_status.zero?

    latest_commit = HTTParty.get("#{GITHUB_API_PATH}/repos/#{repository.full_name}/commits").first
    latest_commit["sha"][...7]
  end

  private

  def run_program(command)
    output, status = Open3.capture2e(command)
    [ output, status.exitstatus ]
  end
end
