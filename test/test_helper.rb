# frozen_string_literal: true

ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rails/test_help'

require 'webmock/minitest'
WebMock.disable_net_connect!(allow_localhost: true)

OmniAuth.config.test_mode = true

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    setup do
      queue_adapter.perform_enqueued_jobs = true
      queue_adapter.perform_enqueued_at_jobs = true
    end

    I18n.default_locale = :en
  end
end

module ActionDispatch
  class IntegrationTest
    def sign_in(user)
      auth_hash = OmniAuth::AuthHash.new(
        provider: 'github',
        uid: '12345',
        info: {
          nickname: user.nickname,
          email: user.email
        },
        credentials: {
          token: user.token
        }
      )

      OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash::InfoHash.new(auth_hash)

      get callback_auth_url('github')
    end

    def signed_in?
      session[:user_id].present? && current_user.present?
    end

    def sign_out
      session.delete(:user_id)
      session.clear
    end

    def current_user
      @current_user ||= User.find_by(id: session[:user_id])
    end
  end
end

# Register test doubles in the DI container to avoid external calls
ApplicationContainer.register(:octokit_client) do
  Class.new do
    def initialize(access_token:, auto_paginate: true); end
    def repo(_id)
      {
        html_url: 'https://github.com/example/repo',
        owner: { login: 'owner' },
        name: 'repo',
        full_name: 'owner/repo',
        language: 'ruby',
        created_at: Time.now,
        updated_at: Time.now
      }
    end
    def repos
      [
        { id: 123456, full_name: 'owner/repo', language: 'ruby' }
      ]
    end
  end
end

ApplicationContainer.register(:fetch_repo_data) do
  ->(_repository, _tmp_path) { 'abcdef0' }
end

ApplicationContainer.register(:lint_check) do
  ->(_tmp_path, _parser_class) { '{}' }
end

# Stub webhook creation to avoid external API calls
class CreateRepositoryWebhookJob
  def perform(repository)
    # Stub implementation for tests
    Rails.logger.debug { "Webhook creation stubbed for repository #{repository.id}" }
  end
end

# WebMock stubs for GitHub API calls
WebMock.stub_request(:get, /api\.github\.com\/repos\/.*\/commits/)
  .to_return(
    status: 200,
    body: [{ 'sha' => 'abcdef0123456789' }].to_json,
    headers: { 'Content-Type' => 'application/json' }
  )

WebMock.stub_request(:get, /api\.github\.com\/user\/repos/)
  .to_return(
    status: 200,
    body: [
      {
        id: 123456,
        full_name: 'owner/repo',
        language: 'ruby',
        html_url: 'https://github.com/owner/repo',
        owner: { login: 'owner' },
        name: 'repo',
        created_at: Time.now,
        updated_at: Time.now
      }
    ].to_json,
    headers: { 'Content-Type' => 'application/json' }
  )

WebMock.stub_request(:get, /api\.github\.com\/repositories\/\d+/)
  .to_return(
    status: 200,
    body: {
      id: 3504920930,
      full_name: 'Hexlet/hexlet-cv',
      language: 'ruby',
      html_url: 'https://github.com/Hexlet/hexlet-cv',
      owner: { login: 'Hexlet' },
      name: 'hexlet-cv',
      created_at: Time.now,
      updated_at: Time.now
    }.to_json,
    headers: { 'Content-Type' => 'application/json' }
  )
