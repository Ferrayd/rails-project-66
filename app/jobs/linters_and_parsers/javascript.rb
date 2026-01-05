# frozen_string_literal: true

module LintersAndParsers
  class Javascript
    def self.linter(temp_repo_path)
      # Удаляем старые конфиги eslint (игнорируем результат)
      run_programm "find #{temp_repo_path} -name '*eslint*.*' -type f -delete"

      command = "yarn run eslint --format json #{temp_repo_path}"
      stdout, stderr, exit_status = run_programm(command)

      # Если команда завершилась с ошибкой, логируем
      if exit_status != 0
        Rails.logger.error { "Javascript.linter: eslint failed with exit_status=#{exit_status}" }
        Rails.logger.error { "Javascript.linter: stderr=#{stderr}" } unless stderr.empty?
        # ESLint может возвращать JSON даже при ошибках, продолжаем обработку
      end

      # Проверяем что stdout не пустой
      if stdout.nil? || stdout.strip.empty?
        Rails.logger.warn { 'Javascript.linter: stdout is empty, returning empty JSON' }
        return '[]'
      end

      # ESLint выводит JSON на третьей строке (первые две - служебные)
      json_line = stdout.split("\n")[2]

      if json_line.nil? || json_line.strip.empty?
        Rails.logger.warn { 'Javascript.linter: JSON line is empty, returning empty array' }
        return '[]'
      end

      json_line # json_string
    end

    def self.parser(temp_repo_path, json_string)
      # Валидация JSON перед парсингом
      if json_string.nil? || json_string.strip.empty?
        Rails.logger.warn { 'Javascript.parser: json_string is empty or nil, returning empty results' }
        return [[], 0]
      end

      begin
        eslint_files_results = JSON.parse(json_string) # array
      rescue JSON::ParserError => e
        Rails.logger.error { "Javascript.parser: JSON parse error: #{e.message}" }
        Rails.logger.error { "Javascript.parser: json_string (first 500 chars): #{json_string[0..500]}" }
        return [[], 0]
      end

      # Проверяем структуру данных
      unless eslint_files_results.is_a?(Array)
        Rails.logger.warn do
          "Javascript.parser: unexpected JSON structure (expected Array, got #{eslint_files_results.class}), returning empty results"
        end
        return [[], 0]
      end

      number_of_violations = 0
      check_results = []

      eslint_files_results
        .filter { |file_result| !file_result['messages'].empty? }
        .each do |file_result|
          src_file = {}
          src_file['filePath'] = file_result['filePath'].partition(temp_repo_path).last
          src_file['messages'] = []
          file_result['messages'].each do |message|
            violation = {}
            violation['message'] = message['message']
            violation['ruleId'] = message['ruleId']
            violation['line'] = message['line']
            violation['column'] = message['column']
            src_file['messages'] << violation
            number_of_violations += 1
          end
          check_results << src_file
        end
      [check_results, number_of_violations]
    end
  end
end
