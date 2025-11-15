# frozen_string_literal: true

class ApplicationContainer
  def self.[](key)
    value = registry.fetch(key)
    value.respond_to?(:call) ? value.call : value
  end

  def self.register(key, value = nil, &block)
    registry[key] = block || value
  end

  def self.registry
    @registry ||= {}
  end
end

# Default registrations for all environments
ApplicationContainer.register(:octokit_client) { Octokit::Client }
ApplicationContainer.register(:fetch_repo_data) { method(:fetch_repo_data) }
ApplicationContainer.register(:lint_check)      { method(:lint_check) }
ApplicationContainer.register(:parse_check)     { method(:parse_check) }
