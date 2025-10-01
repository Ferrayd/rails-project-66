# frozen_string_literal: true

module LintersAndParsers
  class Ruby
    def self.linter(temporary_repository_path)
      stdout_output, _exit_status = run_program "bundle exec rubocop --format json #{temporary_repository_path}"
      stdout_output
    end

    def self.parser(temporary_repository_path, linting_results_json)
      rubocop_file_results = JSON.parse(linting_results_json)["files"]
      process_file_results(rubocop_file_results, temporary_repository_path)
    end

    def self.process_file_results(rubocop_file_results, temporary_repository_path)
      parsed_check_results = []
      violations_count = 0

      rubocop_file_results
        .filter { |file_result| !file_result["offenses"].empty? }
        .each do |file_result|
          file_data, file_violations = parse_file(file_result, temporary_repository_path)
          parsed_check_results << file_data
          violations_count += file_violations
        end

      [ parsed_check_results, violations_count ]
    end

    def self.parse_file(file_result, temporary_repository_path)
      source_file_data = initialize_file_data(file_result, temporary_repository_path)
      source_file_data["messages"], violations_count = process_offenses(file_result["offenses"])
      [ source_file_data, violations_count ]
    end

    def self.initialize_file_data(file_result, temporary_repository_path)
      {
        "filePath" => file_result["path"].partition(temporary_repository_path).last,
        "messages" => []
      }
    end

    def self.process_offenses(offenses)
      ignored_rules = [ "Style/FrozenStringLiteralComment", "Style/StringLiterals", "Style/HashSyntax" ]
      violations = []
      violations_count = 0

      offenses.each do |offense|
        next if ignored_rules.include?(offense["cop_name"])

        violation_data = {
          "message" => offense["message"],
          "ruleId" => offense["cop_name"],
          "line" => offense["location"]["line"],
          "column" => offense["location"]["column"]
        }
        violations << violation_data
        violations_count += 1
      end

      [ violations, violations_count ]
    end

    private_class_method :process_file_results, :parse_file, :initialize_file_data, :process_offenses
  end
end
