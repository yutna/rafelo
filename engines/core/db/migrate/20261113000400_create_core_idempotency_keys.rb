# frozen_string_literal: true

class CreateCoreIdempotencyKeys < ActiveRecord::Migration[8.1]
  def change
    create_table :core_idempotency_keys do |t|
      t.string :token_digest, null: false
      t.string :viewer_id, null: false
      t.string :payload_digest, null: false
      t.string :status, null: false, default: "pending"
      t.integer :attempt, null: false, default: 0
      t.text :outcome
      t.datetime :claimed_at
      t.datetime :expires_at, null: false
      t.timestamps
    end
    add_index :core_idempotency_keys, :token_digest, unique: true
    add_index :core_idempotency_keys, :expires_at
  end
end
