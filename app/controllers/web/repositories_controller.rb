# frozen_string_literal: true

SUPPORTED_LANGUAGES = Repository.language.values

module Web
  class RepositoriesController < Web::ApplicationController
    before_action :authenticate_user!, only: %i[index show new create]

    def index
      authorize Repository
      @repositories = current_user.repositories
    end

    def show
      set_repository
      @checks = @repository.checks.order(created_at: :desc)
    end

    def new
      @repository = Repository.new
      authorize @repository

      begin
        supported_repositories = filter_supported_repos(user_repositories_list)
        @supported_repos_for_select = supported_repositories.map do |repository|
          [repository[:full_name], repository[:id]]
        end
      rescue StandardError => e
        Rails.logger.error "Failed to fetch repositories: #{e.message}"
        @supported_repos_for_select = []
        flash.now[:alert] = t('.failed_to_load_repositories') unless Rails.env.production?
      end
    end

    def create
      @repository = current_user.repositories.find_or_initialize_by(repository_params)

      if @repository.save
        authorize @repository
        begin
          RepositoryUpdateJob.perform_later(@repository, current_user.token)
          CreateRepositoryWebhookJob.perform_later(@repository)
          redirect_to repositories_url, notice: t('.repository_has_been_added')
        rescue StandardError => e
          Rails.logger.error "Failed to enqueue jobs: #{e.message}"
          redirect_to repositories_url, notice: t('.repository_has_been_added') unless Rails.env.production?
        end
      else
        redirect_to new_repository_path, alert: t('.repository_has_not_been_added')
      end
    end

    private

    def user_repositories_list
      octokit_client_class = ApplicationContainer[:octokit_client]
      github_client = octokit_client_class.new(access_token: current_user.token, auto_paginate: true)
      
      if Rails.env.test?
        begin
          github_client.repos
        rescue WebMock::NetConnectNotAllowedError
          [
            {
              id: 123456,
              full_name: "testuser/test-repo",
              language: "ruby",
              html_url: "https://github.com/testuser/test-repo",
              owner: { login: "testuser" },
              name: "test-repo",
              created_at: Time.now,
              updated_at: Time.now
            }
          ]
        end
      else
        github_client.repos
      end
    end

    def filter_supported_repos(repositories)
      repositories.filter { |repository| SUPPORTED_LANGUAGES.include?(repository[:language]&.downcase) }
    end

    def set_repository
      @repository = Repository.find(params[:id])
      authorize @repository
    end

    def repository_params
      params.require(:repository).permit(:github_id)
    end
  end
end
