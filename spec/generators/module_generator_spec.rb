require "rails_helper"
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
      expect(root.join("engines/billing_probe/app/frontend/domain/skeleton.test.ts")).to exist
      expect(File.read(Rails.root.join("config/routes.rb"))).not_to include("billing_probe")
      expect(File.read(Rails.root.join("Gemfile"))).not_to include("billing_probe")
    end
  end

  it "refuses a reserved name without writing files" do
    Dir.mktmpdir do |dir|
      Rails::Generators.invoke("rafelo:module", [ "core" ], destination_root: dir)
      expect(Pathname(dir).join("engines/core")).not_to exist
    end
  end
end
