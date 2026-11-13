# frozen_string_literal: true

class CreateCoreSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :core_sessions do |t|
      t.string :token_digest, null: false
      t.string :viewer_id, null: false
      t.string :viewer_name
      t.text :access_token
      t.text :refresh_token
      t.datetime :access_expires_at
      t.datetime :refreshing_since
      t.integer :refresh_version, null: false, default: 0
      t.datetime :expires_at, null: false
      t.string :locale, null: false, default: "en"
      t.timestamps
    end

    add_index :core_sessions, :token_digest, unique: true
    add_index :core_sessions, :expires_at
  end
end
