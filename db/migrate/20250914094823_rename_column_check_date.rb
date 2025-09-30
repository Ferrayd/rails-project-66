# frozen_string_literal: true

class RenameColumnCheckDate < ActiveRecord::Migration[7.0]
  def change
    rename_column :repository_checks, :check_date, :checked_at
  end
end
