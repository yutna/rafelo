require "rails_helper"
require "securerandom"

# The managed multi-host profile runs the role script as the provider's admin,
# which is not a superuser. PostgreSQL 16+ gives that admin ADMIN OPTION on
# the roles it creates, so the script can grant itself membership in the
# migration role and transfer ownership (OPS-06, OPS-08).
RSpec.describe "Database role script on a managed admin" do
  let(:password) { "drill-password" }

  let(:scratch) { ScratchDatabase.new("rafelo_managed") }
  let(:admin_role) { "rafelo_managed_admin_#{Process.pid}_#{SecureRandom.hex(3)}" }

  before do
    skip "role specs run in the primary test process only (see #333)" if ENV["TEST_ENV_NUMBER"].present?
    skip "requires a PostgreSQL superuser to create the managed admin (see #333)" unless scratch.supported?

    @admin = scratch.admin
    @admin.exec("CREATE ROLE #{@admin.escape_identifier(admin_role)} LOGIN CREATEROLE PASSWORD #{@admin.escape_literal(password)}")
    @admin.exec("CREATE DATABASE #{@admin.escape_identifier(scratch.name)} OWNER #{@admin.escape_identifier(admin_role)}")
    @created = true
    @connection = PG.connect(scratch.options.merge(user: admin_role, password: password))
    @connection.exec(<<~SQL)
      CREATE TABLE core_audits (
        id bigserial PRIMARY KEY,
        occurred_at timestamp(6) without time zone NOT NULL,
        event character varying NOT NULL,
        outcome character varying NOT NULL,
        created_at timestamp(6) without time zone NOT NULL,
        format_version integer DEFAULT 1 NOT NULL
      );
      CREATE TABLE core_sessions (id bigserial PRIMARY KEY);
    SQL
  end

  after do
    if @created
      @connection&.close unless @connection&.finished?
      scratch.drop!
      @admin.exec("DROP ROLE IF EXISTS acme_runtime")
      @admin.exec("DROP ROLE IF EXISTS acme_migrator")
      @admin.exec("DROP ROLE IF EXISTS #{@admin.escape_identifier(admin_role)}")
      scratch.close
    end
  end

  it "transfers ownership and restricts the audit table without a superuser" do
    run_script

    expect(owner("core_audits")).to eq("acme_migrator")
    expect(owner("core_sessions")).to eq("acme_migrator")
    expect(privilege("core_audits", "INSERT")).to be(true)
    expect(privilege("core_audits", "UPDATE")).to be(false)
    expect(privilege("core_audits", "DELETE")).to be(false)
    expect(privilege("core_sessions", "UPDATE")).to be(true)
  end

  def run_script
    script = File.read(Rails.root.join("script/ops/database_roles.sql"))

    @connection.exec(
      script
        .gsub(":'runtime_password'", @connection.escape_literal(password))
        .gsub(":'migration_password'", @connection.escape_literal(password))
    )
  end

  def owner(relation)
    @connection.exec_params(<<~SQL, [ relation ]).getvalue(0, 0)
      SELECT pg_get_userbyid(c.relowner)
      FROM pg_class c
      WHERE c.relname = $1
    SQL
  end

  def privilege(table, privilege)
    @connection.exec_params(
      "SELECT has_table_privilege('acme_runtime', $1, $2)",
      [ table, privilege ]
    ).getvalue(0, 0) == "t"
  end
end
