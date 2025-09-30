# frozen_string_literal: true

class CreateRepositories < ActiveRecord::Migration[7.0]
  def change
    create_table :repositories do |t|
      t.integer :github_repo_id, index: { unique: true }
      t.string :link
      t.string :owner_name
      t.string :repo_name
      t.string :language
      t.datetime :repo_created_at, precision: nil
      t.datetime :repo_updated_at, precision: nil

      t.references :user, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end
  end
end
