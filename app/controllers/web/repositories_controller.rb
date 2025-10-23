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

      filtered_repos = filter_supported_repos(user_repos_list)
      @supported_repos_for_select = filtered_repos.map { |repo| [repo[:full_name], repo[:id]] }
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

    def user_repos_list
      octokit_client = ApplicationContainer[:octokit_client]
      client = octokit_client.new access_token: current_user.token, auto_paginate: true
      client.repos # получение списка репозиториев
    end

    def filter_supported_repos(repos)
      repos.filter { |repo| SUPPORTED_LANGUAGES.include?(repo[:language]&.downcase) }
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
