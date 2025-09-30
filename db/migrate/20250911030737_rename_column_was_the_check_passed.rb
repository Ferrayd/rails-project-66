# frozen_string_literal: true

class RenameColumnWasTheCheckPassed < ActiveRecord::Migration[7.0]
  def change
    rename_column :repository_checks, :was_the_check_passed, :passed
  end
end
