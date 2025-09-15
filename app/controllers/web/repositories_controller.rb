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

      supported_repositories = filter_supported_repos(user_repositories_list)
      @supported_repos_for_select = supported_repositories.map do |repository|
        [repository[:full_name], repository[:id]]
      end
    end

    def create
      @repository = current_user.repositories.find_or_initialize_by(repository_params)

      if @repository.save
        authorize @repository
        RepositoryUpdateJob.perform_later(@repository, current_user.token)
        CreateRepositoryWebhookJob.perform_later(@repository)
        redirect_to repositories_url, notice: t('.repository_has_been_added')
      else
        redirect_to new_repository_path, alert: t('.repository_has_not_been_added')
      end
    end

    private

    def user_repositories_list
      octokit_client_class = ApplicationContainer[:octokit_client]
      github_client = octokit_client_class.new access_token: current_user.token, auto_paginate: true
      github_client.repos # получение списка репозиториев
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
