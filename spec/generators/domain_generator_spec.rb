require "rails_helper"
require "fileutils"
require "json"
require "tmpdir"
require Rails.root.join("engines/core/lib/generators/rafelo/domain_generator")

RSpec.describe Rafelo::Generators::DomainGenerator do
  it "writes a domain engine with no pages, routes or registry entry" do
    Dir.mktmpdir do |dir|
      Rails::Generators.invoke("rafelo:domain", [ "customers_probe", "--skip-post-write" ], destination_root: dir)

      root = Pathname(dir)
      expect(root.join("engines/customers_probe/rafelo_customers_probe.gemspec")).to exist
      expect(root.join("engines/customers_probe/app/frontend/domain/skeleton.test.ts")).to exist
      expect(root.join("engines/customers_probe/config/routes.rb")).not_to exist
      expect(root.join("engines/customers_probe/lib/rafelo/customers_probe/engine.rb").read).not_to include("Modules.register")
    end
  end

  it "restores the grant catalog when post-write fails after the sync" do
    Dir.mktmpdir do |dir|
      root = Pathname(dir)
      grants = root.join("engines/core/spec/fixtures/upstream/api/grants.json")
      manifest = root.join("engines/existing/config/permissions.yml")
      FileUtils.mkdir_p(grants.dirname)
      FileUtils.mkdir_p(manifest.dirname)
      File.write(grants, JSON.pretty_generate("grants" => [ "core:existing:read" ]) + "\n")
      File.write(manifest, "existing:\n  widget:\n    - read\n")
      before = File.read(grants)
      synced = nil
      generator = described_class.new([ "customers_probe" ], {}, destination_root: dir)

      expect {
        generator.send(:with_rollback) do
          FileUtils.mkdir_p(generator.send(:root_path).join("engines/customers_probe"))
          Rafelo::Generators::GrantCatalog.sync(generator.send(:root_path))
          synced = File.read(grants)
          raise "boom"
        end
      }.to raise_error(Thor::Error)

      expect(synced).not_to eq(before)
      expect(File.read(grants)).to eq(before)
      expect(root.join("engines/customers_probe")).not_to exist
    end
  end
end
