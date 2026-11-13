# frozen_string_literal: true

class AddFormatVersionToCoreTables < ActiveRecord::Migration[8.1]
  def change
    add_column :core_sessions, :format_version, :integer, null: false, default: 1
    add_column :core_idempotency_keys, :format_version, :integer, null: false, default: 1
  end
end
