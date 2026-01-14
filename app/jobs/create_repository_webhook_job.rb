class CreateRepositoryWebhookJob < ApplicationJob
  queue_as :default

  def perform(repository)
    return if Rails.env.test?

    user_token = repository.user.token
    octokit_client = ApplicationContainer[:github_client]
    client = octokit_client.new(access_token: user_token, auto_paginate: true)

    url = Rails.application.routes.url_helpers.api_checks_url(host: ENV['APP_HOST'])
    
    hook_info = client.create_hook(
      repository.github_id,
      'web',
      {
        url:,
        content_type: 'json',
        insecure_ssl: Rails.env.production? ? '0' : '1'
      },
      {
        events: ['push'],
        active: true
      }
    )

    Rails.logger.info("Webhook created for #{repository.full_name}: #{hook_info.id}")
  rescue StandardError => e
    Rails.logger.error("Webhook creation failed for #{repository.full_name}: #{e.class} - #{e.message}")
    raise e 
  end
end
