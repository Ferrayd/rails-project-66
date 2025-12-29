# frozen_string_literal: true

class BashRunnerStub
  def self.run(command)
    # Возвращаем пустой вывод и успешный статус для тестов
    ['', 0]
  end
end

