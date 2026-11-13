# frozen_string_literal: true

class AddSessionLifecycleFields < ActiveRecord::Migration[8.1]
  def change
    add_column :core_sessions, :grants_refreshed_at, :datetime
    add_column :core_sessions, :last_seen_at, :datetime
    add_index :core_sessions, :viewer_id
    execute "ALTER TABLE core_sessions SET (fillfactor = 70)"
  end
end
