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

  it "gives the runtime role only INSERT and SELECT on audit tables" do
    sql = File.read(Rails.root.join("script/ops/database_roles.sql"))

    expect(sql).to include("REVOKE UPDATE, DELETE, TRUNCATE ON core_audit_events")
    expect(sql).to include("GRANT SELECT, INSERT ON core_audit_events")
    expect(sql).to include("REVOKE UPDATE, DELETE, TRUNCATE ON %I")
    expect(sql).to include("GRANT SELECT, INSERT ON %I")
  end

  it "keeps the grants restricted when a new partition is created" do
    source = File.read(Rails.root.join("engines/core/app/models/rafelo/core/audit_partitions.rb"))

    expect(source).to include("restrict_grants!")
    expect(source).to include("REVOKE UPDATE, DELETE, TRUNCATE")
  end
end
