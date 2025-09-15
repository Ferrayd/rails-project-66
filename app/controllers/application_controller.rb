# frozen_string_literal: true

class ApplicationController < ActionController::Base
  helper_method :signed_in?, :current_user

  include AuthConcern
  include Pundit::Authorization

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  rescue_from NotAuthenticatedError, with: :user_not_authenticated

  private

  def user_not_authorized
    redirect_to root_path, alert: t('user_not_authorized')
  end

  def user_not_authenticated
    redirect_to root_path, alert: t('user_not_authenticated')
  end
end
