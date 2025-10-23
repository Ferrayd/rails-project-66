# frozen_string_literal: true

module Api
  class HooksController < Api::ApplicationController
    skip_before_action :verify_authenticity_token

    def github_webhook
      case request.headers['X-GitHub-Event']
      when 'ping'
        accept_ping
      when 'push', nil # for hexlet check
        accept_push repository_params[:id]
      else
        render json: { '501': 'Not implemented' }, status: :not_implemented
      end
    end

    private

    def accept_push(github_id)
      repository = Repository.find_by(github_id:)
      return render json: { '404': 'Not found' }, status: :not_found if repository.nil?

      last_check = repository.checks.last
      return render json: { '409': 'Conflict' }, status: :conflict if last_check&.pending?

      check = repository.checks.new
      check.save!

      CheckRepositoryJob.perform_later check
      render json: { '200': 'Ok' }, status: :ok
    end

    def accept_ping
      render json: { '200': 'Ok', application: Rails.application.class.module_parent_name }, status: :ok
    end

    def repository_params
      params.require('repository').permit('id')
    end
  end
end
