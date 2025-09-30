# frozen_string_literal: true

class ChangeColumnNull < ActiveRecord::Migration[7.0]
  def change
    change_column_null :users, :token, from: false, to: true
  end
end
