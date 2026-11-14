require "rails_helper"
require "yaml"

RSpec.describe Rafelo::Core::AuditPartitions do
  let(:partitions) { described_class.new }

  it "creates the current and next month plus the DEFAULT partition" do
    partitions.ensure!

    expect(Rails.application.config.time_zone).to eq("UTC")
    now = Time.current.beginning_of_month
    expect(partitions.partitions.keys).to include(
      "core_audit_events_#{now.strftime("%Y_%m")}",
      "core_audit_events_#{(now + 1.month).strftime("%Y_%m")}"
    )
    expect(partitions.default_rows).to eq(0)
  end

  it "alerts when the DEFAULT partition holds a row" do
    Rafelo::Core::AuditEvent.create!(
      occurred_at: 2.years.from_now,
      event: "write",
      outcome: "success",
      created_at: Time.current
    )

    expect(Rails.error).to receive(:report).with(
      instance_of(described_class::DefaultPartitionOccupied),
      handled: false,
      context: { rows: 1 }
    )

    expect(partitions.alert_default!).to be(true)
  end

  it "restricts a runtime role on the parent, DEFAULT, and monthly partitions" do
    connection = ActiveRecord::Base.connection
    role = "acme_runtime_spec"
    connection.execute("DROP ROLE IF EXISTS #{role}")
    connection.execute("CREATE ROLE #{role} NOSUPERUSER")

    partitions.ensure!(restrict_role: role)

    [ "core_audit_events", "core_audit_events_default", *partitions.partitions.keys ].each do |table|
      expect(connection.select_value("SELECT has_table_privilege('#{role}', '#{table}', 'INSERT')")).to be(true)
      expect(connection.select_value("SELECT has_table_privilege('#{role}', '#{table}', 'SELECT')")).to be(true)
      expect(connection.select_value("SELECT has_table_privilege('#{role}', '#{table}', 'UPDATE')")).to be(false)
      expect(connection.select_value("SELECT has_table_privilege('#{role}', '#{table}', 'DELETE')")).to be(false)
      expect(connection.select_value("SELECT has_table_privilege('#{role}', '#{table}', 'TRUNCATE')")).to be(false)
    end
  ensure
    if connection
      connection.execute("DROP OWNED BY #{role}") rescue nil
      connection.execute("DROP ROLE IF EXISTS #{role}") rescue nil
    end
  end

  it "runs the hourly maintenance job" do
    expect { Rafelo::Core::AuditPartitionMaintenanceJob.perform_now }.not_to raise_error
    config = YAML.load_file(Rails.root.join("config/recurring.yml"), aliases: true)
    expect(config.dig("production", "audit_partition_maintenance", "class"))
      .to eq("Rafelo::Core::AuditPartitionMaintenanceJob")
  end

  it "drops only whole months older than the retention period" do
    connection = ActiveRecord::Base.connection
    connection.execute(<<~SQL)
      CREATE TABLE IF NOT EXISTS core_audit_events_2024_01
        PARTITION OF core_audit_events
        FOR VALUES FROM ('2024-01-01') TO ('2024-02-01')
    SQL
    Rafelo::Core::AuditEvent.create!(
      occurred_at: Time.zone.parse("2024-01-15"),
      event: "write",
      outcome: "success",
      created_at: Time.current
    )

    partitions.drop_old_partitions!(at: Time.zone.parse("2026-11-13"), retention_days: 365)

    expect(connection.table_exists?("core_audit_events_2024_01")).to be(false)
    expect(connection.table_exists?("core_audit_events_#{Time.current.strftime("%Y_%m")}")).to be(true)
  end
end
