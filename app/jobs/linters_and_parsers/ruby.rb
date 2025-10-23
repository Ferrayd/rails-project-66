# frozen_string_literal: true

module LintersAndParsers
  class Ruby
    def self.linter(temp_repo_path)
      # run_programm "find #{temp_repo_path} -name '*eslint*.*' -type f -delete"
      stdout, _exit_status = run_programm "bundle exec rubocop --format json #{temp_repo_path}"
      stdout # json_string
    end

    def self.parser(temp_repo_path, json_string)
      rubocop_data = JSON.parse(json_string) # hash
      rubocop_files_results = rubocop_data['files'] # array

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
