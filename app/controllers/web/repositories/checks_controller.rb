# frozen_string_literal: true

module Web
  module Repositories
    class ChecksController < Web::Repositories::ApplicationController
      before_action :authenticate_user!
      before_action :set_repository, only: %i[show create]

      def show
        @check = Repository::Check.find(params[:id])
        authorize @check
      end

      def create
        last_check = @repository.checks.last
        return redirect_to @repository, alert: t('.wait_for_the_previous_check_to_complete') if last_check&.pending?

        @check = @repository.checks.new
        authorize @check
        @check.save!

        CheckRepositoryJob.perform_later @check
        redirect_to @repository, notice: t('.check_created')
      end

      private

      def set_repository
        @repository = Repository.find(params[:repository_id])
        authorize @repository
      end
    end
  end
end
