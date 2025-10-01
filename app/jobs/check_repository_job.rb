# frozen_string_literal: true

class CheckRepositoryJob < ApplicationJob
  queue_as :default

  def perform(check_or_id)
    check = check_or_id.is_a?(Repository::Check) ? check_or_id : Repository::Check.find(check_or_id)
    perform_lint(check)
  end

  private

  def perform_lint(check)
    repository = check.repository
    parser_class = repository.language_parser_class
    parser = parser_class.new(repository)

    results = parser.run_lint

    check.update!(
      passed: results[:passed],
      number_of_violations: results[:violations].size,
      check_results: results,
      aasm_state: 'finished'
    )
  end
end
