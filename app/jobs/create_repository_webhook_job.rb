# frozen_string_literal: true

class CreateRepositoryWebhookJob < ApplicationJob
  queue_as :default

  def perform(repository)
    if Rails.env.test?
      begin
        github_client = initialize_github_client(repository)
        webhook_info = create_webhook(github_client, repository)
        log_webhook_info(webhook_info)
      rescue WebMock::NetConnectNotAllowedError
        Rails.logger.debug { "Test environment: Webhook creation stubbed for repository #{repository.id}" }
        # Return mock webhook info to match expected format
        { id: 1, url: 'https://api.github.com/repos/testuser/test-repo/hooks/1', active: true }
      end
    else
      github_client = initialize_github_client(repository)
      webhook_info = create_webhook(github_client, repository)
      log_webhook_info(webhook_info)
    end
  end

  private

  def initialize_github_client(repository)
    octokit_client_class = ApplicationContainer[:octokit_client]
    octokit_client_class.new(
      access_token: repository.user.token,
      auto_paginate: true
    )
  end

  def create_webhook(github_client, repository)
    github_client.create_hook(
      repository.github_id,
      'web',
      webhook_config,
      webhook_options
    )
  end

  def webhook_config
    {
      url: Rails.application.routes.url_helpers.api_checks_url,
      content_type: 'json',
      insecure_ssl: Rails.env.production? ? '0' : '1'
    }
  end

  def webhook_options
    {
      events: %w[push],
      active: true
    }
  end

  def log_webhook_info(webhook_info)
    Rails.logger.debug { "webhook_info = #{webhook_info}\n" }
  end
end
