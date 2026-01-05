# frozen_string_literal: true

class RepositoryUpdateJob < ApplicationJob
  queue_as :default

  def perform(repository, token)
    octokit_client = ApplicationContainer[:github_client]
    client = octokit_client.new access_token: token, auto_paginate: true
    github_repo = client.repo(repository.github_id)
    return false if github_repo.nil?

    repository.update(
      link: github_repo[:html_url],
      owner_name: github_repo[:owner][:login],
      name: github_repo[:name],
      full_name: github_repo[:full_name],
      language: github_repo[:language].downcase,
      repo_created_at: github_repo[:created_at],
      repo_updated_at: github_repo[:updated_at]
    )
  rescue StandardError => e
    Rails.logger.debug { "RepositoryUpdateJob error: #{e.message}" }
    raise e unless Rails.env.test?
  end
end
