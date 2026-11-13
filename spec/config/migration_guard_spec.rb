require "rails_helper"
require "yaml"

RSpec.describe "Migration guard" do
  let(:deploy_timeout) do
    YAML.safe_load_file(Rails.root.join("config/deploy.yml"), aliases: true).fetch("deploy_timeout").to_i.seconds
  end

  it "pins strong_migrations and its short lock timeout" do
    expect(Gem.loaded_specs.fetch("strong_migrations").version.to_s).to eq("2.8.0")
    expect(StrongMigrations.lock_timeout).to eq(10.seconds)
    expect(StrongMigrations.remove_invalid_indexes).to be(true)
  end

  it "keeps statements inside the deploy timeout" do
    expect(StrongMigrations.statement_timeout).to be <= deploy_timeout
  end

  it "keeps a concurrent-index expand/contract example" do
    example = Rails.root.join("spec/fixtures/migrations/concurrent_index_example.rb").read
    expect(example).to include("disable_ddl_transaction!")
    expect(example).to include("add_index :invoices, :number, algorithm: :concurrently")
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
