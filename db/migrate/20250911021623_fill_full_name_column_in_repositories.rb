# frozen_string_literal: true

class FillFullNameColumnInRepositories < ActiveRecord::Migration[7.0]
  def change
    Repository.find_each do |repository|
      full_name = "#{repository.owner_name}/#{repository.name}"
      repository.update(full_name: full_name)
    end
  end
end
