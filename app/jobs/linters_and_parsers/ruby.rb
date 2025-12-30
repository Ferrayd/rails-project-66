# frozen_string_literal: true

require 'shellwords'

module LintersAndParsers
  class Ruby
    def self.linter(temp_repo_path)
      rubocop_config_path = Rails.root.join('rubocop.yml')

      temp_repo_path_escaped = temp_repo_path.shellescape

      if rubocop_config_path.exist?
        config_path_escaped = rubocop_config_path.to_s.shellescape
        command = "bundle exec rubocop --config #{config_path_escaped} --format json #{temp_repo_path_escaped}"
      else
        Rails.logger.error { "Ruby.linter: rubocop.yml not found at #{rubocop_config_path}, using default config" }
        command = "bundle exec rubocop --format json #{temp_repo_path_escaped}"
      end

      Rails.logger.debug { "Ruby.linter: executing command: #{command}" }

      stdout, stderr, exit_status = run_programm(command)

      Rails.logger.debug do
        "Ruby.linter: exit_status=#{exit_status}, stdout_length=#{stdout&.length || 0}, stderr_length=#{stderr&.length || 0}"
      end

      if stdout.nil? || stdout.strip.empty?
        Rails.logger.warn { 'Ruby.linter: stdout is empty, returning empty JSON' }
        return '{"files":[]}'
      end

      if exit_status > 1
        Rails.logger.error { "Ruby.linter: rubocop failed with exit_status=#{exit_status}" }
        Rails.logger.error { "Ruby.linter: stderr=#{stderr}" } unless stderr.empty?
        return '{"files":[]}'
      end

      begin
        JSON.parse(stdout)
      rescue JSON::ParserError => e
        Rails.logger.error { "Ruby.linter: stdout contains invalid JSON: #{e.message}" }
        Rails.logger.error { "Ruby.linter: stdout (first 500 chars): #{stdout[0..500]}" }
        return '{"files":[]}'
      end

      stdout
    end

    def self.parser(temp_repo_path, json_string)
      Rails.logger.debug do
        "Ruby.parser: temp_repo_path=#{temp_repo_path}, json_string_length=#{json_string&.length || 0}"
      end

      if json_string.nil? || json_string.strip.empty?
        Rails.logger.warn { 'Ruby.parser: json_string is empty or nil, returning empty results' }
        return [[], 0]
      end

      begin
        rubocop_data = JSON.parse(json_string)
      rescue JSON::ParserError => e
        Rails.logger.error { "Ruby.parser: JSON parse error: #{e.message}" }
        Rails.logger.error { "Ruby.parser: json_string (first 500 chars): #{json_string[0..500]}" }
        return [[], 0]
      end

      unless rubocop_data.is_a?(Hash) && rubocop_data['files'].is_a?(Array)
        Rails.logger.warn { 'Ruby.parser: unexpected JSON structure, returning empty results' }
        Rails.logger.warn { "Ruby.parser: rubocop_data keys: #{rubocop_data.keys.inspect}" }
        return [[], 0]
      end

      rubocop_files_results = rubocop_data['files']

      number_of_violations = 0
      check_results = []

      rubocop_files_results
        .filter { |file_result| !file_result['offenses'].empty? }
        .each do |file_result|
          src_file = {}
          src_file['filePath'] = file_result['path'].partition(temp_repo_path).last
          src_file['messages'] = []
          file_result['offenses'].each do |offense|
            violation = {}
            violation['message'] = offense['message']
            violation['ruleId'] = offense['cop_name']
            violation['line'] = offense['location']['line']
            violation['column'] = offense['location']['column']
            src_file['messages'] << violation
            number_of_violations += 1
          end
          check_results << src_file
        end
      [check_results, number_of_violations]
    end
  end
end
