# frozen_string_literal: true

require 'test_helper'

module Web
  module Repositories
    class RepositoriesControllerTest < ActionDispatch::IntegrationTest
      setup do
        @user = users(:user)
        @repository_attrs = { github_id: 123_456 }
      end

      test 'should get index' do
        sign_in @user

        get repositories_path
        assert_response :success
      end

      test 'should get create' do
        sign_in @user

        post repositories_path, params: { repository: @repository_attrs }

        repository = Repository.find_by(@repository_attrs)

        assert { repository }
      end

      test 'should get show' do
        sign_in @user

        get repository_path(repositories(:one))
        assert_response :success
      end

      test 'not authorize action' do
        get repositories_path

        assert_redirected_to root_path
      end
    end
  end
end
