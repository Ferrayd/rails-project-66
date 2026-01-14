# frozen_string_literal: true

module Api
  class HooksController < Api::ApplicationController
    skip_before_action :verify_authenticity_token

    def github_webhook
      case request.headers['X-GitHub-Event']
      when 'ping'
        accept_ping
      when 'push', nil
        accept_push(github_repository_id)
      else
        render json: { error: 'Not implemented' }, status: :not_implemented
      end
    end

    private

    def accept_push(github_id)
      return render json: { error: 'Missing repository id' }, status: :bad_request if github_id.blank?

      repository = Repository.find_by(github_id:)
      return render json: { error: 'Repository not found' }, status: :not_found if repository.nil?

      last_check = repository.checks.last
      return render json: { error: 'Check already in progress' }, status: :conflict if last_check&.pending?

      check = repository.checks.create!
      CheckRepositoryJob.perform_later(check)

      render json: { status: 'ok', check_id: check.id }, status: :ok
    end

    def accept_ping
      render json: { 
        status: 'ok', 
        application: Rails.application.class.module_parent_name 
      }, status: :ok
    end

    def github_repository_id
      @github_repository_id ||= payload.dig('repository', 'id')
    end

    def payload
      @payload ||= JSON.parse(request.body.read) rescue {}
    end
  end
end
