# frozen_string_literal: true

if Rails.env.test?
  # Полная подмена Octokit-клиента
  class FakeOctokitClient
    def initialize(token: nil)
    end

    def repo(repo_id)
      {
        id: repo_id,
        full_name: "test/repo",
        default_branch: "main",
        language: "Ruby"
      }
    end

    def repos(*)
      [
        {
          id: 1,
          full_name: "test/repo1",
          default_branch: "main",
          language: "Ruby"
        }
      ]
    end
  end

  ApplicationContainer.register(:octokit_client) do
    FakeOctokitClient.new
  end

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
