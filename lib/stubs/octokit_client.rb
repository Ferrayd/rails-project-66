# frozen_string_literal: true

GITHUB_REPOS_JSON_PATH = 'test/fixtures/files/github_repos.json'

module Stubs
  class OctokitClient
    def initialize(*args); end

    def repos
      github_repositories_data = JSON.load_file File.open(GITHUB_REPOS_JSON_PATH) # array of "github" repos
      github_repositories_data.each(&:deep_symbolize_keys!)
    end

    def repo(github_repository_id)
      repositories_from_file = repos

      found_repository = repositories_from_file.find { |repository| repository[:id] == github_repository_id }
      return found_repository if found_repository.present?

      repositories_count = repositories_from_file.size
      repository_index = (github_repository_id % repositories_count)
      selected_repository = repositories_from_file[repository_index]
      selected_repository[:id] = github_repository_id
      selected_repository
    end

    def create_hook(*args, **kwargs); end
  end
end
