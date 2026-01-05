# frozen_string_literal: true

require 'test_helper'

module Api
  class HooksControllerTest < ActionDispatch::IntegrationTest
    test 'should accept ping event' do
      post api_checks_path,
           headers: { 'X-GitHub-Event' => 'ping', 'CONTENT_TYPE' => 'application/json' }

      assert_response :ok
      body = response.parsed_body
      assert_equal 'Ok', body['200']
      assert_equal Rails.application.class.module_parent_name, body['application']
    end

    test 'should return 404 if repository not found on push' do
      json = { repository: { id: 999_999 } }.to_json

      post api_checks_path,
           params: json,
           headers: { 'X-GitHub-Event' => 'push', 'CONTENT_TYPE' => 'application/json' }

      assert_response :not_found
      body = response.parsed_body
      assert_equal 'Not found', body['404']
    end

    test 'should return 409 if last check is pending' do
      repository = repositories(:one)
      Repository::Check.create!(repository: repository, aasm_state: 'created') # pending состояние

      json = { repository: { id: repository.github_id } }.to_json

      post api_checks_path,
           params: json,
           headers: { 'X-GitHub-Event' => 'push', 'CONTENT_TYPE' => 'application/json' }

      assert_response :conflict
      body = response.parsed_body
      assert_equal 'Conflict', body['409']
    end

    test 'should return 501 for unsupported event' do
      post api_checks_path,
           headers: { 'X-GitHub-Event' => 'issues', 'CONTENT_TYPE' => 'application/json' }

      assert_response :not_implemented
      body = response.parsed_body
      assert_equal 'Not implemented', body['501']
    end
  end
end
