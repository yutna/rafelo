# frozen_string_literal: true

class CreateCoreAudits < ActiveRecord::Migration[8.1]
  def up
    create_table :core_audits do |t|
      t.datetime :occurred_at, null: false
      t.string :event, null: false
      t.string :outcome, null: false
      t.string :target
      t.string :viewer_id
      t.string :request_id
      t.string :trace_id
      t.string :ip
      t.string :user_agent_family
      t.datetime :created_at, null: false
    end
    add_index :core_audits, [ :event, :occurred_at ]
    add_index :core_audits, :viewer_id

    # The database, not application code, makes audit rows append-only.
    safety_assured do
      execute <<~SQL
        CREATE FUNCTION rafelo_core_audits_append_only() RETURNS trigger AS $$
        BEGIN
          RAISE EXCEPTION 'core_audits is append-only';
        END;
        $$ LANGUAGE plpgsql;

        CREATE TRIGGER rafelo_core_audits_no_update
          BEFORE UPDATE OR DELETE ON core_audits
          FOR EACH ROW EXECUTE FUNCTION rafelo_core_audits_append_only();
      SQL
    end
  end

  def down
    execute "DROP TRIGGER IF EXISTS rafelo_core_audits_no_update ON core_audits"
    execute "DROP FUNCTION IF EXISTS rafelo_core_audits_append_only()"
    drop_table :core_audits
  end
end
