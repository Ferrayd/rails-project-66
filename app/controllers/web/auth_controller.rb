# frozen_string_literal: true

module Web
  class AuthController < Web::ApplicationController
    def callback
      user_info = request.env['omniauth.auth']
      email, nickname = user_info[:info].values_at(:email, :nickname)
      token = user_info['credentials']['token'] # Токен пользователя, потребуется нам позднее
      user = User.find_or_initialize_by(email: email.downcase)
      user.update(nickname:, token:)

      sign_in user
      redirect_to root_path, notice: t('.signed_in')
    end

    def logout
      sign_out
      redirect_to root_path, notice: t('.signed_out')
    end
  end
end
