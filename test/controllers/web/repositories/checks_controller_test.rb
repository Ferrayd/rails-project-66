# frozen_string_literal: true

require "test_helper"

module Web
  module Repositories
    class ChecksControllerTest < ActionDispatch::IntegrationTest
      setup do
        @user = users(:user)
      end

      test "should create check" do
        sign_in @user

        repository = repositories(:one)

        post repository_checks_path(repository)

        check = Repository::Check.find_by(repository_id: repository.id)

        assert_redirected_to repository
        assert { check }
      end

      test "not authorize action" do
        get repositories_path

        assert_redirected_to root_path
      end
    end
  end
end
