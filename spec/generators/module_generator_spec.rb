require "rails_helper"
require "fileutils"
require "json"
require "tmpdir"
require Rails.root.join("engines/core/lib/generators/rafelo/module_generator")

RSpec.describe Rafelo::Generators::ModuleGenerator do
  it "writes a wired module without editing routes or the Gemfile" do
    Dir.mktmpdir do |dir|
      Rails::Generators.invoke("rafelo:module", [ "billing_probe", "--icon", "receipt", "--skip-post-write" ], destination_root: dir)

      root = Pathname(dir)
      expect(root.join("engines/billing_probe/rafelo_billing_probe.gemspec")).to exist
      expect(root.join("engines/billing_probe/config/module.rb").read).to include("Rafelo::Core::Modules.register")
      expect(root.join("engines/billing_probe/config/locales/en.yml")).to exist
      engine_source = File.read(root.join("engines/billing_probe/lib/rafelo/billing_probe/engine.rb"))
      blank_before_end = engine_source.lines.each_cons(2).any? { |line, next_line| line.strip.empty? && next_line.strip == "end" }
      expect(blank_before_end).to be(false)
      expect(YAML.safe_load_file(root.join("engines/billing_probe/config/ratchets.yml"))).to eq(
        "eslint_disable" => 0,
        "rubocop_disable" => 0,
        "use_no_memo" => 0,
        "skipped_tests" => 0,
        "page_budget_overrides" => 0,
        "legacy_table_prefixes" => 0,
        "legacy_constants" => 0
      )
      expect(root.join("engines/billing_probe/app/frontend/domain/skeleton.test.ts")).to exist
      expect(YAML.safe_load_file(root.join("engines/billing_probe/config/permissions.yml"))).to eq(
        "billing_probe" => { "widgets" => [ "read" ] }
      )
      expect(File.read(Rails.root.join("config/routes.rb"))).not_to include("billing_probe")
      expect(File.read(Rails.root.join("Gemfile"))).not_to include("billing_probe")
    end
  end

  it "writes the navigation order as a literal computed at generation time" do
    Dir.mktmpdir do |dir|
      Rails::Generators.invoke("rafelo:module", [ "billing_probe", "--skip-post-write" ], destination_root: dir)

      config = File.read(File.join(dir, "engines/billing_probe/config/module.rb"))
      expect(config).to match(/nav: \{ order: \d+,/)
      expect(config).not_to include("Modules.all")
    end
  end

  it "restores the grant catalog when post-write fails after the sync" do
    Dir.mktmpdir do |dir|
      root = Pathname(dir)
      grants = root.join("config/grants.json")
      manifest = root.join("engines/existing/config/permissions.yml")
      FileUtils.mkdir_p(grants.dirname)
      FileUtils.mkdir_p(manifest.dirname)
      File.write(grants, JSON.pretty_generate("grants" => [ "core:existing:read" ]) + "\n")
      File.write(manifest, "existing:\n  widget:\n    - read\n")
      before = File.read(grants)
      synced = nil
      generator = described_class.new([ "billing_probe" ], {}, destination_root: dir)

      expect {
        generator.send(:with_rollback) do
          FileUtils.mkdir_p(generator.send(:root_path).join("engines/billing_probe"))
          Rafelo::Generators::GrantCatalog.sync(generator.send(:root_path))
          synced = File.read(grants)
          raise "boom"
        end
      }.to raise_error(Thor::Error)

      expect(synced).not_to eq(before)
      expect(File.read(grants)).to eq(before)
      expect(root.join("engines/billing_probe")).not_to exist
    end
  end

  it "refuses a reserved name without writing files" do
    Dir.mktmpdir do |dir|
      Rails::Generators.invoke("rafelo:module", [ "core" ], destination_root: dir)
      expect(Pathname(dir).join("engines/core")).not_to exist
    end
  end
end
