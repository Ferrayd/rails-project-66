# frozen_string_literal: true

class DefaultParser
  def initialize(repository); end

  def run_lint
    { passed: true, violations: [] }
  end
end
