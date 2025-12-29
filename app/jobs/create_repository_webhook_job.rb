# frozen_string_literal: true

class CreateRepositoryWebhookJob < ApplicationJob
  queue_as :default

  def perform(repository)
    return if Rails.env.test?

    user_token = repository.user.token

    octokit_client = ApplicationContainer[:github_client]
    client = octokit_client.new(access_token: user_token, auto_paginate: true)

    url = Rails.application.routes.url_helpers.api_checks_url
    hook_info = client.create_hook(
      repository.github_id,
      'web',
      {
        url:,
        content_type: 'json',
        insecure_ssl: Rails.env.production? ? '0' : '1'
      },
      {
        events: %w[push],
        active: true
      }
    )

    Rails.logger.debug { "hook_info = #{hook_info}\n" }
  rescue StandardError => e
    Rails.logger.debug { "Webhook creation failed: #{e.class} - #{e.message}" }
  end
end
