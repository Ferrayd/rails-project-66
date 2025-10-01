# frozen_string_literal: true

module LintersAndParsers
  class Javascript
    def self.linter(temporary_repository_path)
      run_program "find #{temporary_repository_path} -name '*eslint*.*' -type f -delete"
      stdout_output, _exit_status = run_program "yarn run eslint --format json #{temporary_repository_path}"
      stdout_output.split("\n")[2] # returns json_string
    end

    def self.parser(temporary_repository_path, linting_results_json)
      eslint_file_results = JSON.parse(linting_results_json)
      process_file_results(eslint_file_results, temporary_repository_path)
    end

    def self.parse_file(file_result, temporary_repository_path)
      source_file_data = initialize_file_data(file_result, temporary_repository_path)
      source_file_data["messages"], violations_count = process_messages(file_result["messages"])
      [ source_file_data, violations_count ]
    end

    def self.process_file_results(eslint_file_results, temporary_repository_path)
      parsed_check_results = []
      violations_count = 0

      eslint_file_results
        .filter { |file_result| !file_result["messages"].empty? }
        .each do |file_result|
          file_data, file_violations = parse_file(file_result, temporary_repository_path)
          parsed_check_results << file_data
          violations_count += file_violations
        end

      [ parsed_check_results, violations_count ]
    end

    def self.initialize_file_data(file_result, temporary_repository_path)
      {
        "filePath" => file_result["filePath"].partition(temporary_repository_path).last,
        "messages" => []
      }
    end

    def self.process_messages(messages)
      violations = []
      violations_count = 0

      messages.each do |message|
        violation_data = {
          "message" => message["message"],
          "ruleId" => message["ruleId"],
          "line" => message["line"],
          "column" => message["column"]
        }
        violations << violation_data
        violations_count += 1
      end

      [ violations, violations_count ]
    end

    private_class_method :parse_file, :process_file_results, :initialize_file_data, :process_messages
  end
end
