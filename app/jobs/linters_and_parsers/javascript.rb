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
      return [[], 0] if empty_json_string?(json_string)

      eslint_files_results = parse_json(json_string)
      return [[], 0] unless eslint_files_results

      return [[], 0] unless valid_array_structure?(eslint_files_results)

      process_eslint_files(temp_repo_path, eslint_files_results)
    end

    def self.empty_json_string?(json_string)
      return false unless json_string.nil? || json_string.strip.empty?

      Rails.logger.warn { 'Javascript.parser: json_string is empty or nil, returning empty results' }
      true
    end

    def self.parse_json(json_string)
      JSON.parse(json_string)
    rescue JSON::ParserError => e
      Rails.logger.error { "Javascript.parser: JSON parse error: #{e.message}" }
      Rails.logger.error { "Javascript.parser: json_string (first 500 chars): #{json_string[0..500]}" }
      nil
    end

    def self.valid_array_structure?(eslint_files_results)
      return true if eslint_files_results.is_a?(Array)

      Rails.logger.warn do
        "Javascript.parser: unexpected JSON structure (expected Array, got #{eslint_files_results.class}), returning empty results"
      end
      false
    end

    def self.process_eslint_files(temp_repo_path, eslint_files_results)
      number_of_violations = 0
      check_results = []

      eslint_files_results
        .filter { |file_result| !file_result['messages'].empty? }
        .each do |file_result|
          src_file = build_src_file(temp_repo_path, file_result)
          check_results << src_file
          number_of_violations += src_file['messages'].size
        end
      [check_results, number_of_violations]
    end

    def self.build_src_file(temp_repo_path, file_result)
      src_file = {}
      src_file['filePath'] = file_result['filePath'].partition(temp_repo_path).last
      src_file['messages'] = file_result['messages'].map do |message|
        {
          'message' => message['message'],
          'ruleId' => message['ruleId'],
          'line' => message['line'],
          'column' => message['column']
        }
      end
      src_file
    end
  end
end
