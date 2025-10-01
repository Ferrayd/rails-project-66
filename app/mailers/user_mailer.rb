# frozen_string_literal: true

class UserMailer < ApplicationMailer
  default from: "#{Rails.application.class.module_parent_name}@checks.com"

  def repo_check_failed
    repo_check_or_verification_failed
  end

  def repo_check_verification_failed
    repo_check_or_verification_failed
  end

  private

  def repo_check_or_verification_failed
    @check = params[:check]
    repo = @check.repository
    @repo_full_name = repo.full_name
    @user = repo.user
    mail(to: @user.email, subject: t('.subject', repo_full_name: @repo_full_name))
  end
end
