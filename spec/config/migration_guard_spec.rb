require "rails_helper"
require "yaml"

RSpec.describe "Migration guard" do
  it "pins strong_migrations and its short lock timeout" do
    expect(Gem.loaded_specs.fetch("strong_migrations").version.to_s).to eq("2.8.0")
    expect(StrongMigrations.lock_timeout).to eq(10.seconds)
    expect(StrongMigrations.remove_invalid_indexes).to be(true)
  end

  it "leaves boot time inside both deploy timeouts" do
    [ "config/deploy.yml", "config/deploy.multi.yml" ].each do |path|
      timeout = YAML.safe_load_file(Rails.root.join(path), aliases: true)
        .fetch("deploy_timeout").to_i.seconds

      expect(timeout).to be > StrongMigrations.statement_timeout
    end
  end

  it "keeps a concurrent-index expand/contract example" do
    example = Rails.root.join("spec/fixtures/migrations/concurrent_index_example.rb").read
    expect(example).to include("disable_ddl_transaction!")
    expect(example).to include("add_index :invoices, :number, algorithm: :concurrently")
  end

  it "runs db:prepare as the migration role" do
    expect(Rails.root.join("bin/docker-entrypoint").read).to include("ACME_DATABASE_ROLE=migration ./bin/rails db:prepare")
    expect(Rails.root.join("config/database.yml").read).to include("ACME_DATABASE_ROLE")
  end

  it "boots one host at a time with an explicit deploy timeout" do
    %w[config/deploy.yml config/deploy.multi.yml].each do |path|
      config = YAML.safe_load_file(Rails.root.join(path), aliases: true)

      expect(config.fetch("deploy_timeout")).to be_a(Integer).and be_positive
      expect(config.dig("boot", "limit")).to eq(1)
    end
  end
end
