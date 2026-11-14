require "rails_helper"

RSpec.describe "Database roles" do
  it "defines the runtime and migration credentials in database.yml" do
    database = File.read(Rails.root.join("config/database.yml"))

    expect(database).to include("RAFELO_DATABASE_ROLE")
    expect(database).to include("DB_MIGRATION_USER")
    expect(database).to include("DB_MIGRATION_PASSWORD")
    expect(database).to include("primary:")
    expect(database).to include("migration:")
    expect(database).to include("database_tasks: false")
    expect(database).to include(":migration_password")
  end

  it "defines the runtime and migration connection configurations" do
    require "erb"
    data = YAML.safe_load(ERB.new(File.read(Rails.root.join("config/database.yml"))).result, aliases: true)
    production = data.fetch("production")

    expect(production.dig("primary", "username")).to include("rafelo_runtime")
    expect(production.dig("migration", "username")).to eq("rafelo_migrator")
    expect(production.dig("migration", "database_tasks")).to be(false)
  end

  it "gives the runtime role only INSERT and SELECT on both audit generations" do
    sql = File.read(Rails.root.join("script/ops/database_roles.sql"))

    expect(sql).to include("'core_audits', 'core_audit_events'")
    expect(sql).to include("REVOKE UPDATE, DELETE, TRUNCATE ON public.%I")
    expect(sql).to include("GRANT SELECT, INSERT ON public.%I")
    expect(sql).to include("ALTER TABLE public.%I OWNER TO rafelo_migrator")
  end

  it "keeps the grants restricted when a new partition is created" do
    source = File.read(Rails.root.join("engines/core/app/models/rafelo/core/audit_partitions.rb"))

    expect(source).to include("restrict_grants!")
    expect(source).to include("REVOKE UPDATE, DELETE, TRUNCATE")
    expect(source).to include("DEFAULT_TABLE")
  end

  it "keeps the audit partitions out of the structure dump" do
    flags = ActiveRecord::Tasks::DatabaseTasks.structure_dump_flags

    expect(flags).to include("--exclude-table=core_audit_events_*")
  end
end
