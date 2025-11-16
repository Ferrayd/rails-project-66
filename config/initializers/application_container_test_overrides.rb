# frozen_string_literal: true

if Rails.env.test?

  class FakeOctokitClient
    def initialize(access_token: nil, auto_paginate: nil); end

    def repos
      [
        {
          id: 1,
          full_name: 'user/test-repo',
          language: 'Ruby',
          default_branch: 'main'
        },
        {
          id: 2,
          full_name: 'user/js-repo',
          language: 'Javascript',
          default_branch: 'main'
        }
      ]
    end

    def repo(_github_id)
      {
        html_url: 'https://github.com/user/test-repo',
        owner: { login: 'user' },
        name: 'test-repo',
        full_name: 'user/test-repo',
        language: 'Ruby',
        created_at: Time.zone.now,
        updated_at: Time.zone.now
      }
    end
  end

  ApplicationContainer.register(:octokit_client) { FakeOctokitClient }

  ApplicationContainer.register(:fetch_repo_data) do
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

  ApplicationContainer.register(:lint_check) do
    ->(_temp_repo_path, _language_class) { '{}' }
  end

  ApplicationContainer.register(:parse_check) do
    ->(_temp_repo_path, _language_class, _json_string) { [[], 0] }
  end
end
