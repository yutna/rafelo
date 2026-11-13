require "rails_helper"
require "yaml"

RSpec.describe "Retention policies" do
  let(:config) { Rails.application.config.x }

  it "keeps idempotency keys at least one margin beyond the absolute session lifetime" do
    expect(config.idempotency.retention_seconds).to be > config.sessions.absolute_timeout_seconds
    expect(config.idempotency.retention_seconds - config.sessions.absolute_timeout_seconds).to be >= 3600
  end

  it "expires export files after a few hours" do
    expect(config.exports.ttl_seconds).to be_between(1.hour.to_i, 12.hours.to_i)
  end

  it "caps cache age, cable messages, and finished queue jobs" do
    cache = Rails.application.config_for(:cache)
    cable = YAML.load_file(Rails.root.join("config/cable.yml"), aliases: true)
    recurring = YAML.load_file(Rails.root.join("config/recurring.yml"), aliases: true)

    expect(cache.dig(:store_options, :max_age).to_i).to be_between(1.day.to_i, 90.days.to_i)
    expect(cable.dig("production", "message_retention")).to eq("1.day")
    expect(recurring.dig("production", "clear_solid_queue_finished_jobs", "command"))
      .to include("clear_finished_in_batches")
    expect(recurring.dig("production", "clear_solid_queue_finished_jobs", "schedule")).to be_present
  end

  it "schedules every batched sweep" do
    recurring = YAML.load_file(Rails.root.join("config/recurring.yml"), aliases: true)
    production = recurring.fetch("production")

    expect(production.dig("session_sweep", "class")).to eq("Rafelo::Core::SessionSweepJob")
    expect(production.dig("idempotency_sweep", "class")).to eq("Rafelo::Core::IdempotencySweepJob")
    expect(production.dig("export_sweep", "class")).to eq("Rafelo::Core::ExportSweepJob")
    [ "session_sweep", "idempotency_sweep", "export_sweep" ].each do |name|
      expect(production.dig(name, "schedule")).to be_present
    end
  end
end
