require "rails_helper"
require "fileutils"
require "json"
require "tmpdir"
require Rails.root.join("engines/core/lib/generators/rafelo/base/grant_catalog")

RSpec.describe Rafelo::Generators::GrantCatalog do
  it "adds every manifest key the fake upstream catalog is missing" do
    Dir.mktmpdir("rafelo-grant-catalog-") do |dir|
      grants_path = File.join(dir, "engines/core/spec/fixtures/upstream/api/grants.json")
      manifest_path = File.join(dir, "engines/billing/config/permissions.yml")
      FileUtils.mkdir_p(File.dirname(grants_path))
      FileUtils.mkdir_p(File.dirname(manifest_path))
      File.write(grants_path, JSON.pretty_generate("grants" => [ "billing:invoice:read" ]) + "\n")
      File.write(manifest_path, "billing:\n  invoice:\n    - read\n    - create\n  customer:\n    - read\n")

      described_class.sync(dir)

      expect(JSON.parse(File.read(grants_path)).fetch("grants")).to eq(
        [
          "billing:customer:read",
          "billing:invoice:create",
          "billing:invoice:read"
        ]
      )
    end
  end

  it "leaves the catalog alone when it already has every key" do
    Dir.mktmpdir("rafelo-grant-catalog-") do |dir|
      grants_path = File.join(dir, "engines/core/spec/fixtures/upstream/api/grants.json")
      manifest_path = File.join(dir, "engines/billing/config/permissions.yml")
      FileUtils.mkdir_p(File.dirname(grants_path))
      FileUtils.mkdir_p(File.dirname(manifest_path))
      File.write(grants_path, JSON.pretty_generate("grants" => [ "billing:invoice:read" ]) + "\n")
      File.write(manifest_path, "billing:\n  invoice:\n    - read\n")
      before = File.read(grants_path)

      described_class.sync(dir)

      expect(File.read(grants_path)).to eq(before)
    end
  end
end
