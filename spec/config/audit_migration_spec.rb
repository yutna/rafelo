require "rails_helper"
require "stringio"
require Rails.root.join("engines/core/db/migrate/20261114000000_partition_core_audit_events").to_s

# Exercises the expand migration against a v0.18.0-shaped core_audits table in
# a throwaway database: the expand copy keeps the legacy rows, and a rollback
# copies the v0.19.0 rows back without duplicating the rows it already copied
# (BE-22, OPS-08).
RSpec.describe "Audit partition migration" do
  let(:scratch) { ScratchDatabase.new("rafelo_audit_migration") }

  before do
    skip "requires a PostgreSQL superuser to create a scratch database (see #333)" unless scratch.supported?

    scratch.create!
    @created = true
    config = ActiveRecord::DatabaseConfigurations::HashConfig.new(
      "test", "audit_migration", scratch.options.merge(adapter: "postgresql")
    )
    pool_config = ActiveRecord::ConnectionAdapters::PoolConfig.new(
      ActiveRecord::Base, config, :writing, :default
    )
    @pool = ActiveRecord::ConnectionAdapters::ConnectionPool.new(pool_config)
    @connection = @pool.checkout
    @connection.execute(<<~SQL)
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
      INSERT INTO core_audits (
        occurred_at, event, outcome, target, viewer_id, request_id, trace_id,
        ip, user_agent_family, created_at, format_version
      ) VALUES (
        '2026-10-01 10:00:00', 'sign_in', 'success', 'viewer-1', 'viewer-1',
        'req-legacy', 'trace-legacy', '203.0.113.0/24', 'chrome',
        '2026-10-01 10:00:00', 1
      );
    SQL

    @migration = PartitionCoreAuditEvents.new
    @migration.instance_variable_set(:@connection, @connection)
  end

  after do
    @pool&.disconnect!
    scratch.drop! if @created
    scratch.close
  end

  it "copies the legacy rows once on expand and once back on contract" do
    quietly { @migration.send(:up) }

    expect(core_audits_count).to eq(1)
    expect(core_audit_events_count).to eq(1)

    @connection.execute(<<~SQL)
      INSERT INTO core_audit_events (
        occurred_at, event, outcome, target, viewer_id, request_id, trace_id,
        ip, user_agent_family, created_at, format_version
      ) VALUES (
        '2026-11-14 01:00:00', 'sign_in', 'success', 'viewer-2', 'viewer-2',
        'req-new', 'trace-new', '203.0.113.0/24', 'chrome',
        '2026-11-14 01:00:00', 1
      );
    SQL

    quietly { @migration.send(:down) }

    expect(core_audits_count).to eq(2)
    expect(@connection.select_value("SELECT to_regclass('core_audit_events')::text")).to be_nil
  end

  def quietly
    original = $stdout
    $stdout = StringIO.new
    yield
  ensure
    $stdout = original
  end

  def core_audits_count
    @connection.select_value("SELECT count(*) FROM core_audits").to_i
  end

  def core_audit_events_count
    @connection.select_value("SELECT count(*) FROM core_audit_events").to_i
  end
end
