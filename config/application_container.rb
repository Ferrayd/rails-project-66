# frozen_string_literal: true

class ApplicationContainer
  class << self
    def register(name, &block)
      registry[name] = block
    end

    def [](name)
      registry[name].call
    end

    private

    def registry
      @registry ||= {}
    end
  end
end

ApplicationContainer.register(:fetch_repo_data) { method(:fetch_repo_data) }
ApplicationContainer.register(:lint_check) { method(:lint_check) }
