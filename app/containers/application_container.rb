# frozen_string_literal: true

class ApplicationContainer
  class << self
    def register(name, &block)
      registry[name] = block
    end

    def [](name)
      registry.fetch(name).call
    end

    private

    def registry
      @registry ||= {}
    end
  end
end
