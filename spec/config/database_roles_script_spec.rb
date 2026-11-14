require "rails_helper"

# Runs the operator-facing role script for real against a throwaway database,
# so the grants and ownership transfer are proved by PostgreSQL, not by
# matching strings in the SQL file (OPS-06, OPS-08).
RSpec.describe "Database role script" do
  let(:password) { "drill-password" }

  let(:scratch) { ScratchDatabase.new("rafelo_roles") }
  let(:roles) { %w[acme_runtime acme_migrator] }

  before do
    skip "role specs run in the primary test process only (see #333)" if ENV["TEST_ENV_NUMBER"].present?
    skip "requires a PostgreSQL superuser to create roles (see #333)" unless scratch.supported?

    scratch.create!
    @created = true
    @connection = scratch.connect
    @connection.exec(<<~SQL)
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
      CREATE TABLE core_audit_events (id bigserial PRIMARY KEY);
      CREATE TABLE core_audit_events_2026_11 (id bigserial PRIMARY KEY);
      CREATE TABLE core_sessions (id bigserial PRIMARY KEY);
    SQL
  end

  after do
    if @created
      @connection&.close unless @connection&.finished?
      scratch.drop!
      scratch.drop_roles!(roles)
      scratch.close
    end
  end

  it "creates both roles and hands existing tables to the migration role" do
    run_script

    expect(role?("acme_runtime")).to be(true)
    expect(role?("acme_migrator")).to be(true)
    expect(owner("core_audits")).to eq("acme_migrator")
    expect(owner("core_sessions")).to eq("acme_migrator")
    expect(owner("core_audits_id_seq")).to eq("acme_migrator")
  end

  it "keeps every audit table append-only for the runtime role" do
    run_script

    %w[core_audits core_audit_events core_audit_events_2026_11].each do |table|
      expect(privilege(table, "SELECT", "acme_runtime")).to be(true)
      expect(privilege(table, "INSERT", "acme_runtime")).to be(true)
      expect(privilege(table, "UPDATE", "acme_runtime")).to be(false)
      expect(privilege(table, "DELETE", "acme_runtime")).to be(false)
      expect(privilege(table, "TRUNCATE", "acme_runtime")).to be(false)
    end

    expect(privilege("core_sessions", "UPDATE", "acme_runtime")).to be(true)
  end

  it "grants the runtime role DML on tables the migration role creates later" do
    run_script
    @connection.exec("SET ROLE acme_migrator")
    @connection.exec("CREATE TABLE later_table (id bigserial PRIMARY KEY)")
    @connection.exec("RESET ROLE")

    expect(privilege("later_table", "UPDATE", "acme_runtime")).to be(true)
    expect(sequence_privilege("later_table_id_seq", "USAGE", "acme_runtime")).to be(true)
  end

  it "is re-runnable without changing the result" do
    run_script
    expect { run_script }.not_to raise_error
    expect(owner("core_audits")).to eq("acme_migrator")
    expect(privilege("core_audits", "UPDATE", "acme_runtime")).to be(false)
  end

  def run_script
    script = File.read(Rails.root.join("script/ops/database_roles.sql"))

    @connection.exec(
      script
        .gsub(":'runtime_password'", @connection.escape_literal(password))
        .gsub(":'migration_password'", @connection.escape_literal(password))
    )
  end

  def role?(name)
    @connection.exec_params("SELECT 1 FROM pg_roles WHERE rolname = $1", [ name ]).ntuples.positive?
  end

  def owner(relation)
    @connection.exec_params(<<~SQL, [ relation ]).getvalue(0, 0)
      SELECT pg_get_userbyid(c.relowner)
      FROM pg_class c
      WHERE c.relname = $1
    SQL
  end

  def privilege(table, privilege, role)
    @connection.exec_params(
      "SELECT has_table_privilege($1, $2, $3)",
      [ role, table, privilege ]
    ).getvalue(0, 0) == "t"
  end

  def sequence_privilege(sequence, privilege, role)
    @connection.exec_params(
      "SELECT has_sequence_privilege($1, $2, $3)",
      [ role, sequence, privilege ]
    ).getvalue(0, 0) == "t"
  end
end
