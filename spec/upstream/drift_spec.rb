require "rails_helper"
require "yaml"

RSpec.describe "Fixture drift" do
  it "offers every permission key declared by a module manifest" do
    grants = JSON.parse(Rails.root.join("config/grants.json").read).fetch("grants")
    manifests = Dir[Rails.root.join("engines/*/config/permissions.yml")]

    manifests.each do |path|
      manifest = YAML.load_file(path)
      manifest.each do |prefix, resources|
        resources.each do |resource, actions|
          actions.each do |action|
            expect(grants).to include("#{prefix}:#{resource}:#{action}"), "#{path}: #{prefix}:#{resource}:#{action}"
          end
        end
      end
    end
  end

  # The generator rebuilds the keys of every manifest prefix, so a permission
  # that a manifest no longer declares must not survive in the catalog.
  it "keeps no grant that a manifest prefix no longer declares" do
    grants = JSON.parse(Rails.root.join("config/grants.json").read).fetch("grants")
    declared = Dir[Rails.root.join("engines/*/config/permissions.yml")].flat_map do |path|
      YAML.load_file(path).flat_map do |prefix, resources|
        resources.flat_map do |resource, actions|
          actions.map { |action| "#{prefix}:#{resource}:#{action}" }
        end
      end
    end
    owned = declared.map { |key| key.split(":").first }.uniq

    stale = grants.select { |grant| owned.include?(grant.split(":").first) } - declared
    expect(stale).to eq([])
  end
end
