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

      stdout, stderr, exit_status = run_programm(command)

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
      return [[], 0] if empty_json_string?(json_string)

      rubocop_data = parse_json(json_string)
      return [[], 0] unless rubocop_data

      rubocop_files_results = validate_and_extract_files(rubocop_data)
      return [[], 0] unless rubocop_files_results

      process_rubocop_files(temp_repo_path, rubocop_files_results)
    end

    def self.empty_json_string?(json_string)
      return false unless json_string.nil? || json_string.strip.empty?

      Rails.logger.warn { 'Ruby.parser: json_string is empty or nil, returning empty results' }
      true
    end

    def self.parse_json(json_string)
      JSON.parse(json_string)
    rescue JSON::ParserError => e
      Rails.logger.error { "Ruby.parser: JSON parse error: #{e.message}" }
      Rails.logger.error { "Ruby.parser: json_string (first 500 chars): #{json_string[0..500]}" }
      nil
    end

    def self.validate_and_extract_files(rubocop_data)
      if rubocop_data.is_a?(Hash) && rubocop_data['files'].is_a?(Array)
        return rubocop_data['files']
      end

      Rails.logger.warn { 'Ruby.parser: unexpected JSON structure, returning empty results' }
      Rails.logger.warn { "Ruby.parser: rubocop_data keys: #{rubocop_data.keys.inspect}" }
      nil
    end

    def self.process_rubocop_files(temp_repo_path, rubocop_files_results)
      number_of_violations = 0
      check_results = []

      rubocop_files_results
        .filter { |file_result| !file_result['offenses'].empty? }
        .each do |file_result|
          src_file = build_src_file(temp_repo_path, file_result)
          check_results << src_file
          number_of_violations += src_file['messages'].size
        end
      [check_results, number_of_violations]
    end

    def self.build_src_file(temp_repo_path, file_result)
      src_file = {}
      src_file['filePath'] = file_result['path'].partition(temp_repo_path).last
      src_file['messages'] = file_result['offenses'].map do |offense|
        {
          'message' => offense['message'],
          'ruleId' => offense['cop_name'],
          'line' => offense['location']['line'],
          'column' => offense['location']['column']
        }
      end
      src_file
    end
  end
end
