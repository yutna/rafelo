# frozen_string_literal: true

class AddGrantsGenerationToCoreSessions < ActiveRecord::Migration[8.1]
  def change
    add_column :core_sessions, :grants_generation, :integer, null: false, default: 0
    add_column :core_sessions, :grants_fetched_generation, :integer, null: false, default: 0
  end
end
