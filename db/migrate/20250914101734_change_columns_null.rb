# frozen_string_literal: true

class ChangeColumnsNull < ActiveRecord::Migration[7.0]
  def change
    change_column_null :repositories, :github_id, false
    change_column_null :repository_checks, :aasm_state, false
    change_column_null :repository_checks, :checked_at, false
  end
end
