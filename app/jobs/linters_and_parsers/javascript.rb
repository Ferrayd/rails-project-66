# frozen_string_literal: true

module LintersAndParsers
  class Javascript
    def self.linter(temp_repo_path)
      run_programm "find #{temp_repo_path} -name '*eslint*.*' -type f -delete"
      stdout, _exit_status = run_programm "yarn run eslint --format json #{temp_repo_path}"
      stdout.split("\n")[2] # json_string
    end

    def self.parser(temp_repo_path, json_string)
      eslint_files_results = JSON.parse(json_string) # array

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
