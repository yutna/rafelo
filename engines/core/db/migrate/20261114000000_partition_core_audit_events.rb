# frozen_string_literal: true

class PartitionCoreAuditEvents < ActiveRecord::Migration[8.1]
  TABLE = "core_audit_events"

  def up
    safety_assured do
      execute "DROP TRIGGER IF EXISTS rafelo_core_audits_no_update ON core_audits"
      execute "DROP FUNCTION IF EXISTS rafelo_core_audits_append_only()"
      execute "ALTER TABLE core_audits RENAME TO core_audits_legacy"

      execute <<~SQL
        CREATE TABLE #{TABLE} (
          id bigserial NOT NULL,
          occurred_at timestamp(6) without time zone NOT NULL,
          event character varying NOT NULL,
          outcome character varying NOT NULL,
          target character varying,
          viewer_id character varying,
          request_id character varying,
          trace_id character varying,
          ip character varying,
          user_agent_family character varying,
          resource character varying,
          action character varying,
          upstream_id character varying,
          policy character varying,
          page character varying,
          created_at timestamp(6) without time zone NOT NULL,
          format_version integer DEFAULT 1 NOT NULL
        ) PARTITION BY RANGE (occurred_at);
        CREATE INDEX index_core_audit_events_on_event_and_occurred_at ON #{TABLE} (event, occurred_at);
        CREATE INDEX index_core_audit_events_on_viewer_id ON #{TABLE} (viewer_id);
        CREATE INDEX index_core_audit_events_on_id ON #{TABLE} (id);
        CREATE TABLE core_audit_events_default PARTITION OF #{TABLE} DEFAULT;
      SQL

      legacy_months = select_values(<<~SQL).map { |value| Time.zone.parse(value.to_s).beginning_of_month }
        SELECT DISTINCT date_trunc('month', occurred_at) FROM core_audits_legacy ORDER BY 1
      SQL
      (legacy_months + [ Time.current.beginning_of_month, 1.month.from_now.beginning_of_month ])
        .uniq
        .each { |month| create_month_partition(month) }

      execute <<~SQL
        CREATE FUNCTION rafelo_core_audit_events_append_only() RETURNS trigger AS $$
        BEGIN
          RAISE EXCEPTION 'core_audit_events is append-only';
        END;
        $$ LANGUAGE plpgsql;

        CREATE TRIGGER rafelo_core_audit_events_no_update
          BEFORE UPDATE OR DELETE ON #{TABLE}
          FOR EACH ROW EXECUTE FUNCTION rafelo_core_audit_events_append_only();

        INSERT INTO #{TABLE} (
          occurred_at, event, outcome, target, viewer_id, request_id, trace_id,
          ip, user_agent_family, created_at, format_version
        )
        SELECT
          occurred_at, event, outcome, target, viewer_id, request_id, trace_id,
          ip, user_agent_family, created_at, format_version
        FROM core_audits_legacy;

        DROP TABLE core_audits_legacy;
      SQL
    end
  end

  def down
    safety_assured do
      execute "DROP TRIGGER IF EXISTS rafelo_core_audit_events_no_update ON #{TABLE}"
      execute "DROP FUNCTION IF EXISTS rafelo_core_audit_events_append_only()"
      execute "DROP TABLE IF EXISTS #{TABLE} CASCADE"

      execute <<~SQL
        CREATE TABLE core_audits (
          id bigserial PRIMARY KEY,
          occurred_at timestamp(6) without time zone NOT NULL,
          event character varying NOT NULL,
          outcome character varying NOT NULL,
          target character varying,
          viewer_id character varying,
          request_id character varying,
          trace_id character varying,
          ip character varying,
          user_agent_family character varying,
          created_at timestamp(6) without time zone NOT NULL,
          format_version integer DEFAULT 1 NOT NULL
        );
        CREATE INDEX index_core_audits_on_event_and_occurred_at ON core_audits (event, occurred_at);
        CREATE INDEX index_core_audits_on_viewer_id ON core_audits (viewer_id);

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

  private

  def create_month_partition(month)
    name = "core_audit_events_#{month.strftime("%Y_%m")}"
    execute <<~SQL
      CREATE TABLE IF NOT EXISTS #{name}
        PARTITION OF #{TABLE}
        FOR VALUES FROM ('#{month.strftime("%Y-%m-%d")}') TO ('#{month.next_month.strftime("%Y-%m-%d")}')
    SQL
  end
end
