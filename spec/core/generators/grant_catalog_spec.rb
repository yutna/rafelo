require "rails_helper"
require "fileutils"
require "json"
require "tmpdir"
require Rails.root.join("engines/core/lib/generators/rafelo/base/grant_catalog")

RSpec.describe Rafelo::Generators::GrantCatalog do
  def grants_fixture(dir, catalog, manifest)
    grants_path = File.join(dir, "config/grants.json")
    manifest_path = File.join(dir, "engines/billing/config/permissions.yml")
    FileUtils.mkdir_p(File.dirname(grants_path))
    FileUtils.mkdir_p(File.dirname(manifest_path))
    File.write(grants_path, JSON.pretty_generate(catalog) + "\n")
    File.write(manifest_path, manifest)
    grants_path
  end

  it "adds every manifest key the fake upstream catalog is missing" do
    Dir.mktmpdir("rafelo-grant-catalog-") do |dir|
      grants_path = grants_fixture(
        dir,
        { "grants" => [ "billing:invoice:read" ] },
        "billing:\n  invoice:\n    - read\n    - create\n  customer:\n    - read\n"
      )

      described_class.sync(dir)

      catalog = JSON.parse(File.read(grants_path))
      expect(catalog.fetch("grants")).to eq(
        [
          "billing:customer:read",
          "billing:invoice:create",
          "billing:invoice:read"
        ]
      )
      expect(catalog.fetch("generated")).to eq(
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
      grants_path = grants_fixture(
        dir,
        { "grants" => [ "billing:invoice:read" ], "generated" => [ "billing:invoice:read" ] },
        "billing:\n  invoice:\n    - read\n"
      )
      before = File.read(grants_path)

      described_class.sync(dir)

      expect(File.read(grants_path)).to eq(before)
    end
  end

  it "drops a generated key whose permission no longer exists" do
    Dir.mktmpdir("rafelo-grant-catalog-") do |dir|
      grants_path = grants_fixture(
        dir,
        {
          "grants" => [ "billing:invoice:read", "billing:widget:read" ],
          "generated" => [ "billing:widget:read" ]
        },
        "billing:\n  invoice:\n    - read\n"
      )

      described_class.sync(dir)

      catalog = JSON.parse(File.read(grants_path))
      expect(catalog.fetch("grants")).to eq([ "billing:invoice:read" ])
      expect(catalog.fetch("generated")).to eq([ "billing:invoice:read" ])
    end
  end

  it "records the marker without dropping a grant in a legacy catalog" do
    Dir.mktmpdir("rafelo-grant-catalog-") do |dir|
      grants_path = grants_fixture(
        dir,
        { "grants" => [ "billing:invoice:read", "billing:widget:read" ] },
        "billing:\n  invoice:\n    - read\n"
      )

      described_class.sync(dir)

      catalog = JSON.parse(File.read(grants_path))
      expect(catalog.fetch("grants")).to eq([ "billing:invoice:read", "billing:widget:read" ])
      expect(catalog.fetch("generated")).to eq([ "billing:invoice:read" ])
    end
  end
end
