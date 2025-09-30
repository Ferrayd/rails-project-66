# frozen_string_literal: true

class RenameColumn < ActiveRecord::Migration[7.0]
  def change
    rename_column :repositories, :repo_name, :name
    rename_column :repositories, :github_repo_id, :github_id
  end
end
