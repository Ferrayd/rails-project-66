# frozen_string_literal: true

class RepositoryUpdateJob < ApplicationJob
  queue_as :default

  def perform(repository, access_token)
    octokit_client_class = ApplicationContainer[:octokit_client]
    github_client = octokit_client_class.new(access_token: access_token, auto_paginate: true)
    github_repository_data = github_client.repo(repository.github_id)
    return false if github_repository_data.nil?

    repository.update(
      link: github_repository_data[:html_url],
      owner_name: github_repository_data[:owner][:login],
      name: github_repository_data[:name],
      full_name: github_repository_data[:full_name],
      language: github_repository_data[:language].downcase,
      repo_created_at: github_repository_data[:created_at],
      repo_updated_at: github_repository_data[:updated_at]
    )
  end
end
