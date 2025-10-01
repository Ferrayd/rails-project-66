# frozen_string_literal: true

ApplicationContainer.register(:fetch_repo_data) { FetchRepoData.new }
ApplicationContainer.register(:lint_check) { LintCheck.new }
ApplicationContainer.register(:parse_check) { ParseCheck.new }
