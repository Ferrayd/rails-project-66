# frozen_string_literal: true

class RemoveColumnCheckedAtFromRepositoryChecks < ActiveRecord::Migration[7.0]
  def change
    remove_column :repository_checks, :checked_at, :datetime
  end
end
