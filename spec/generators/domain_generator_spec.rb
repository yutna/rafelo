require "rails_helper"
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
end
