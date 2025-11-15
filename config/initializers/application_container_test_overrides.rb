# frozen_string_literal: true

if Rails.env.test?

  class FakeOctokitClient
    def initialize(access_token: nil, auto_paginate: nil); end

    def repos
      [
        { id: 1, full_name: 'user/test-repo', language: 'ruby', default_branch: 'main' },
        { id: 2, full_name: 'user/js-repo', language: 'javascript', default_branch: 'main' }
      ]
    end

    def repo(id)
      { id: id, full_name: 'user/test-repo', language: 'ruby', default_branch: 'main' }
    end

  end

  ApplicationContainer.register(:octokit_client) { FakeOctokitClient }

  ApplicationContainer.register(:fetch_repo_data) do
    ->(repository, _temp_repo_path) do
      repository.language ||= 'ruby'
      repository.name ||= 'test-repo'
      repository.full_name ||= 'user/test-repo'

      'abcdef0'
    end
  end

  ApplicationContainer.register(:lint_check) do
    ->(_temp_repo_path, _language_class) { '{}' }
  end

  ApplicationContainer.register(:parse_check) do
    ->(_temp_repo_path, _language_class, _json_string) { [[], 0] }
  end
end
