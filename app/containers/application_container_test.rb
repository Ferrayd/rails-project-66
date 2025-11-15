# frozen_string_literal: true

module ApplicationContainerTest
  if Rails.env.test?
    ApplicationContainer.register(:fetch_repo_data) { ->(_repo, _path) { "abcdef0" } }
    ApplicationContainer.register(:lint_check)      { ->(_path, _lang) { "{}" } }
    ApplicationContainer.register(:parse_check)     { ->(_path, _lang, _json) { [[], 0] } }
  end
end
