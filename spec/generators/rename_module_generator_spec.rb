require "rails_helper"
require "tmpdir"
require "yaml"
require Rails.root.join("engines/core/lib/generators/rafelo/rename_module_generator")

RSpec.describe Rafelo::Generators::RenameModuleGenerator do
  it "renames engine and keeps module path/permission prefixes stable" do
    Dir.mktmpdir do |dir|
      root = Pathname(dir)
      src = root.join("engines/billing")
      FileUtils.mkdir_p(src.join("config/initializers"))
      FileUtils.mkdir_p(src.join("lib/rafelo/billing"))
      File.write(src.join("package.yml"), YAML.dump("enforce_dependencies" => "strict", "dependencies" => []))
      File.write(src.join("config/ratchets.yml"), YAML.dump("eslint_disable" => 0))
      File.write(src.join("config/module.rb"), <<~RUBY)
        Rafelo::Core::Modules.register(
          key: :billing,
          engine: Object,
          path: "/billing",
          permission_prefixes: ["billing"],
          nav: { order: 10, label_key: "billing.nav.title", icon: "folder" }
        )
      RUBY
      File.write(src.join("config/permissions.yml"), YAML.dump("billing" => { "widgets" => [ "read" ] }))
      File.write(src.join("lib/rafelo/billing/engine.rb"), "module Rafelo::Billing; class Engine < Rails::Engine; end; end\n")
      dependent = root.join("engines/shipper")
      FileUtils.mkdir_p(dependent)
      File.write(dependent.join("package.yml"), YAML.dump("dependencies" => [ "engines/core", "engines/billing" ]))
      engine_spec = src.join("spec/requests/widgets_spec.rb")
      FileUtils.mkdir_p(engine_spec.dirname)
      File.write(engine_spec, <<~RUBY)
        RSpec.describe "billing/widgets" do
          let(:fixture) { Rails.root.join("engines/billing/spec/fixtures/upstream/widgets/index.json") }
          it { get "/en/billing/widgets"; page_context.urls.route(:billing, :widgets) }
        end
      RUBY

      described_class.start([ "billing", "invoicing", "--skip-post-write" ], destination_root: dir)

      expect(root.join("engines/billing")).not_to exist
      expect(root.join("engines/invoicing")).to exist
      mod_rb = File.read(root.join("engines/invoicing/config/module.rb"))
      expect(mod_rb).to include('path: "/billing"')
      expect(mod_rb).to include('"billing"')
      expect(mod_rb).not_to include('permission_prefixes: ["invoicing"]')

      perms = YAML.safe_load(File.read(root.join("engines/invoicing/config/permissions.yml")))
      expect(perms).to have_key("billing")
      expect(perms).not_to have_key("invoicing")
      expect(perms.dig("billing", "widgets")).to eq([ "read" ])

      pkg = YAML.safe_load(File.read(root.join("engines/invoicing/package.yml")))
      expect(pkg.dig("metadata", "legacy_table_prefix")).to eq("billing")
      expect(root.join("engines/invoicing/config/initializers/legacy_constants.rb")).to exist
      ratchets = YAML.safe_load(File.read(root.join("engines/invoicing/config/ratchets.yml")))
      expect(ratchets["legacy_table_prefixes"]).to eq(1)
      expect(ratchets["legacy_constants"]).to eq(1)

      dependent_package = YAML.safe_load(File.read(dependent.join("package.yml")))
      expect(dependent_package["dependencies"]).to eq([ "engines/core", "engines/invoicing" ])

      spec = File.read(root.join("engines/invoicing/spec/requests/widgets_spec.rb"))
      expect(spec).to include('"invoicing/widgets"')
      expect(spec).to include("engines/invoicing/spec/fixtures/upstream/widgets/index.json")
      expect(spec).to include("route(:invoicing")
      expect(spec).to include('get "/en/billing/widgets"')
    end
  end

  it "restores the tree when rename fails mid-run" do
    Dir.mktmpdir do |dir|
      root = Pathname(dir)
      src = root.join("engines/billing")
      FileUtils.mkdir_p(src.join("config/initializers"))
      FileUtils.mkdir_p(src.join("lib/rafelo/billing"))
      File.write(src.join("package.yml"), YAML.dump("enforce_dependencies" => "strict", "dependencies" => []))
      File.write(src.join("config/ratchets.yml"), YAML.dump("eslint_disable" => 0))
      File.write(src.join("config/module.rb"), "Rafelo::Core::Modules.register(key: :billing, engine: Object, path: \"/billing\", permission_prefixes: [\"billing\"], nav: { order: 10 })\n")
      File.write(src.join("config/permissions.yml"), YAML.dump("billing" => { "widgets" => [ "read" ] }))
      File.write(src.join("lib/rafelo/billing/engine.rb"), "module Rafelo::Billing; class Engine < Rails::Engine; end; end\n")
      before = Dir[root.join("**/*")].select { |p| File.file?(p) }.sort.map { |p| [ p, File.binread(p) ] }

      allow_any_instance_of(described_class).to receive(:write_legacy_constants).and_raise("boom")

      expect {
        begin
          described_class.start([ "billing", "invoicing", "--skip-post-write" ], destination_root: dir)
        rescue SystemExit, Thor::Error
          nil
        end
      }.not_to raise_error

      after = Dir[root.join("**/*")].select { |p| File.file?(p) }.sort.map { |p| [ p, File.binread(p) ] }
      expect(after).to eq(before)
    end
  end
end
