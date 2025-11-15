# frozen_string_literal: true

if Rails.env.test?
  ApplicationContainer.register(:fetch_repo_data) do
    ->(_repo_id) do
      {
        id: 123,
        full_name: "test/repo",
        default_branch: "main",
        language: "Ruby"
      }
    end
  end

  ApplicationContainer.register(:lint_check) do
    ->(_path, _lang) { "{}" }
  end

  ApplicationContainer.register(:parse_check) do
    ->(_path, _lang, _json) { [[], 0] }
  end
end
