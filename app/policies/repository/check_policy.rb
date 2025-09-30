# frozen_string_literal: true

class Repository
  class CheckPolicy < ApplicationPolicy
    def show?
      owner?
    end

    def create?
      owner?
    end

    def owner?
      user == record.repository.user
    end
  end
end
