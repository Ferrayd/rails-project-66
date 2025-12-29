# frozen_string_literal: true

require 'dry/container'

class ApplicationContainer
  extend Dry::Container::Mixin

  if Rails.env.test?
    # Тестовые заглушки
    require_relative 'test_stubs/github_client_stub'
    require_relative 'test_stubs/bash_runner_stub'
    require_relative 'test_stubs/git_stub'

    register :github_client, -> { GithubClientStub }
    register :bash_runner, -> { BashRunnerStub }
    register :git, -> { GitStub }

    # Функции для тестов
    register :fetch_repo_data do
      lambda do |repository, _temp_repo_path|
        repository.language ||= 'ruby'
        repository.name ||= 'test-repo'
        repository.full_name ||= 'user/test-repo'
        repository.link ||= 'https://github.com/user/test-repo'
        repository.owner_name ||= 'user'
        repository.repo_created_at ||= Time.zone.now
        repository.repo_updated_at ||= Time.zone.now

        'abcdef0'
      end
    end

    register :lint_check do
      ->(_temp_repo_path, _language_class) { '{}' }
    end

    register :parse_check do
      ->(_temp_repo_path, _language_class, _json_string) { [[], 0] }
    end
  else
    # Боевое/разработка окружение
    register :github_client, -> { Octokit::Client }
    register :bash_runner, -> { BashRunner } if defined?(BashRunner)
    register :git, -> { Git } if defined?(Git)

    # Реальные функции будут определены в check_repository_job.rb
    # Используем ленивую загрузку через lambda
    register :fetch_repo_data do
      lambda do |repository, temp_repo_path|
        run_programm "rm -rf #{temp_repo_path}"

        _, exit_status = run_programm "git clone #{repository.link}.git #{temp_repo_path}"
        raise StandardError unless exit_status.zero?

        github_client_class = ApplicationContainer[:github_client]
        client = github_client_class.new(access_token: repository.user.token)

        commit = client.commits(repository.full_name).first
        commit.sha[0..6]
      end
    end

    register :lint_check do
      lambda do |temp_repo_path, language_class|
        language_class.linter(temp_repo_path) # json_string
      end
    end

    register :parse_check do
      lambda do |temp_repo_path, language_class, json_string|
        language_class.parser(temp_repo_path, json_string) # [check_results, number_of_violations]
      end
    end
  end
end

# Вспомогательная функция для выполнения команд
def run_programm(command)
  stdout, exit_status = Open3.popen3(command) do |_stdin, stdout, _stderr, wait_thr|
    [stdout.read, wait_thr.value]
  end
  [stdout, exit_status.exitstatus]
end
