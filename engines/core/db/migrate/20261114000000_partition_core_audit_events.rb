# frozen_string_literal: true

# Expand phase (BE-22): the v0.18.0 release writes to core_audits, so that
# table and its trigger stay in place while core_audit_events is introduced.
# A later release, after old containers are gone, is the contract step that
# archives and drops core_audits.
class PartitionCoreAuditEvents < ActiveRecord::Migration[8.1]
  TABLE = "core_audit_events"

  def up
    safety_assured do
      execute <<~SQL
        CREATE TABLE IF NOT EXISTS #{TABLE} (
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
        CREATE INDEX IF NOT EXISTS index_core_audit_events_on_event_and_occurred_at ON #{TABLE} (event, occurred_at);
        CREATE INDEX IF NOT EXISTS index_core_audit_events_on_viewer_id ON #{TABLE} (viewer_id);
        CREATE INDEX IF NOT EXISTS index_core_audit_events_on_id ON #{TABLE} (id);
        CREATE TABLE IF NOT EXISTS core_audit_events_default PARTITION OF #{TABLE} DEFAULT;
      SQL

      legacy_months = legacy_months_in_use
      (legacy_months + [ Time.current.beginning_of_month, 1.month.from_now.beginning_of_month ])
        .uniq
        .each { |month| create_month_partition(month) }

      execute <<~SQL
        CREATE OR REPLACE FUNCTION rafelo_core_audit_events_append_only() RETURNS trigger AS $$
        BEGIN
          RAISE EXCEPTION 'core_audit_events is append-only';
        END;
        $$ LANGUAGE plpgsql;

        DROP TRIGGER IF EXISTS rafelo_core_audit_events_no_update ON #{TABLE};
        CREATE TRIGGER rafelo_core_audit_events_no_update
          BEFORE UPDATE OR DELETE ON #{TABLE}
          FOR EACH ROW EXECUTE FUNCTION rafelo_core_audit_events_append_only();
      SQL

      if table_exists?(:core_audits)
        execute <<~SQL
          INSERT INTO #{TABLE} (
            occurred_at, event, outcome, target, viewer_id, request_id, trace_id,
            ip, user_agent_family, created_at, format_version
          )
          SELECT
            occurred_at, event, outcome, target, viewer_id, request_id, trace_id,
            ip, user_agent_family, created_at, format_version
          FROM core_audits;
        SQL
      end
    end
  end

  def down
    safety_assured do
      if table_exists?(:core_audits)
        execute <<~SQL
          INSERT INTO core_audits (
            occurred_at, event, outcome, target, viewer_id, request_id, trace_id,
            ip, user_agent_family, created_at, format_version
          )
          SELECT
            e.occurred_at, e.event, e.outcome, e.target, e.viewer_id, e.request_id,
            e.trace_id, e.ip, e.user_agent_family, e.created_at, e.format_version
          FROM #{TABLE} e
          WHERE NOT EXISTS (
            SELECT 1 FROM core_audits c
            WHERE c.occurred_at IS NOT DISTINCT FROM e.occurred_at
              AND c.event IS NOT DISTINCT FROM e.event
              AND c.outcome IS NOT DISTINCT FROM e.outcome
              AND c.target IS NOT DISTINCT FROM e.target
              AND c.viewer_id IS NOT DISTINCT FROM e.viewer_id
              AND c.request_id IS NOT DISTINCT FROM e.request_id
              AND c.trace_id IS NOT DISTINCT FROM e.trace_id
              AND c.ip IS NOT DISTINCT FROM e.ip
              AND c.user_agent_family IS NOT DISTINCT FROM e.user_agent_family
              AND c.created_at IS NOT DISTINCT FROM e.created_at
              AND c.format_version IS NOT DISTINCT FROM e.format_version
          );
        SQL
      end

      execute "DROP TRIGGER IF EXISTS rafelo_core_audit_events_no_update ON #{TABLE}"
      execute "DROP FUNCTION IF EXISTS rafelo_core_audit_events_append_only()"
      execute "DROP TABLE IF EXISTS #{TABLE} CASCADE"
    end
  end

  private

  def legacy_months_in_use
    return [] unless table_exists?(:core_audits)

    select_values(<<~SQL).map { |value| Time.zone.parse(value.to_s).beginning_of_month }
      SELECT DISTINCT date_trunc('month', occurred_at) FROM core_audits ORDER BY 1
    SQL
  end

  def create_month_partition(month)
    name = "core_audit_events_#{month.strftime("%Y_%m")}"
    execute <<~SQL
      CREATE TABLE IF NOT EXISTS #{name}
        PARTITION OF #{TABLE}
        FOR VALUES FROM ('#{month.strftime("%Y-%m-%d")}') TO ('#{month.next_month.strftime("%Y-%m-%d")}')
    SQL
  end
end
