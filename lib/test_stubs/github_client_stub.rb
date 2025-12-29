# frozen_string_literal: true

class GithubClientStub
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

  def commits(_full_name)
    [
      OpenStruct.new(sha: 'abcdef0123456789')
    ]
  end

  def create_hook(_repo_id, _type, _config, _options)
    { 'id' => 123, 'test_mode' => true }
  end
end

