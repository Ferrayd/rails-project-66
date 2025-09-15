# frozen_string_literal: true

COMMIT_ID = '5702e5b'
ESLINTER_JSON_PATH = 'test/fixtures/files/eslinter_good.json'
RUBOCOP_JSON_PATH = 'test/fixtures/files/rubocop.json'
LINTERS_RESULT_MAP = { 'Javascript' => ESLINTER_JSON_PATH, 'JavaScript' => ESLINTER_JSON_PATH,
                       'Ruby' => RUBOCOP_JSON_PATH }.freeze

module Stubs
  autoload :OctokitClient, './lib/stubs/octokit_client'

  def self.fetch_repo_data(_repository, _temp_repo_path)
    COMMIT_ID
  end

  def self.lint_check(_temp_repo_path, language_class)
    language = language_class.to_s.split('::').last
    File.read(LINTERS_RESULT_MAP[language]) # json_string
  end
end
