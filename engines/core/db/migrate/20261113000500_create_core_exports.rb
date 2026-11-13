# frozen_string_literal: true

class CreateCoreExports < ActiveRecord::Migration[8.1]
  def change
    create_table :core_exports do |t|
      t.string :viewer_id, null: false
      t.string :status, null: false, default: "pending"
      t.string :filename, null: false
      t.datetime :expires_at, null: false
      t.timestamps
    end
    add_index :core_exports, [ :viewer_id, :created_at ]
    add_index :core_exports, :expires_at
  end
end
