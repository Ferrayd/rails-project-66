# frozen_string_literal: true

class AddFullNameToRepositories < ActiveRecord::Migration[7.0]
  def change
    add_column :repositories, :full_name, :string
  end
end
