# frozen_string_literal: true

class AddPermissionGrantsToCoreSessions < ActiveRecord::Migration[8.1]
  def change
    add_column :core_sessions, :permission_grants, :jsonb, null: false, default: []
    add_column :core_sessions, :grant_digest, :string
  end
end
