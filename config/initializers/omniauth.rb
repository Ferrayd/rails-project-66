# frozen_string_literal: true

# Подключите гем omniauth. Для интеграции с Github нам потребуются следующие скоупы user,public_repo,admin:repo_hook
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :github, ENV.fetch("GITHUB_CLIENT_ID", nil), ENV.fetch("GITHUB_CLIENT_SECRET", nil),
           scope: "user,public_repo,admin:repo_hook"
end
