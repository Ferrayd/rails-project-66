# frozen_string_literal: true

class ApplicationContainer
  extend Dry::Container::Mixin

  if Rails.env.test?
    autoload :Stubs, './lib/stubs'
    register :octokit_client, -> { Stubs::OctokitClient }
    register :fetch_repo_data, ->(repository, temp_repo_path) { Stubs.fetch_repo_data(repository, temp_repo_path) }
    register :lint_check, ->(temp_repo_path, language_class) { Stubs.lint_check(temp_repo_path, language_class) }
  else
    register :octokit_client, -> { Octokit::Client }
    register :fetch_repo_data, ->(repository, temp_repo_path) { fetch_repo_data(repository, temp_repo_path) }
    register :lint_check, ->(temp_repo_path, language_class) { lint_check(temp_repo_path, language_class) }
  end
end
