# frozen_string_literal: true

module TestStubs
  class BashRunnerStub
    def self.run(_command)
      ['', 0]
    end
  end
end
