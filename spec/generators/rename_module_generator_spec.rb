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

      described_class.start([ "billing", "invoicing", "--skip-post-write" ], destination_root: dir)

      expect(root.join("engines/billing")).not_to exist
      expect(root.join("engines/invoicing")).to exist
      mod_rb = File.read(root.join("engines/invoicing/config/module.rb"))
      expect(mod_rb).to include('path: "/billing"')
      expect(mod_rb).to include('"billing"')
      expect(mod_rb).not_to include('permission_prefixes: ["invoicing"]')

      pkg = YAML.safe_load(File.read(root.join("engines/invoicing/package.yml")))
      expect(pkg.dig("metadata", "legacy_table_prefix")).to eq("billing")
      expect(root.join("engines/invoicing/config/initializers/legacy_constants.rb")).to exist
      ratchets = YAML.safe_load(File.read(root.join("engines/invoicing/config/ratchets.yml")))
      expect(ratchets["legacy_table_prefixes"]).to eq(1)
      expect(ratchets["legacy_constants"]).to eq(1)
    end
  end
end
