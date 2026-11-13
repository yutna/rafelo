require "rails_helper"

RSpec.describe "Migration guard" do
  it "pins strong_migrations and its short lock timeout" do
    expect(Gem.loaded_specs.fetch("strong_migrations").version.to_s).to eq("2.8.0")
    expect(StrongMigrations.lock_timeout).to eq(10.seconds)
    expect(StrongMigrations.remove_invalid_indexes).to be(true)
  end

  it "runs db:prepare as the migration role" do
    expect(Rails.root.join("bin/docker-entrypoint").read).to include("RAFELO_DATABASE_ROLE=migration ./bin/rails db:prepare")
    expect(Rails.root.join("config/database.yml").read).to include("RAFELO_DATABASE_ROLE")
  end

  it "boots one host at a time with an explicit deploy timeout" do
    expect(Rails.root.join("config/deploy.yml").read).to include("deploy_timeout: 120")
    expect(Rails.root.join("config/deploy.yml").read).to match(/^boot:\n  limit: 1$/)
  end
end
