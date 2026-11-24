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

  # The catalog records which grants a manifest generated. A key left behind by
  # a removed or renamed permission shows up here instead of surviving forever.
  it "records exactly the generated keys and no stale one" do
    catalog = JSON.parse(Rails.root.join("config/grants.json").read)
    generated = catalog["generated"]
    # A catalog written before the marker existed is migrated by the next
    # generator run; the kernel's update never rewrites an app-owned catalog.
    next if generated.nil?

    expected = Dir[Rails.root.join("engines/*/config/permissions.yml")].flat_map do |path|
      YAML.load_file(path).flat_map do |prefix, resources|
        resources.flat_map do |resource, actions|
          actions.map { |action| "#{prefix}:#{resource}:#{action}" }
        end
      end
    end.uniq.sort

    expect(generated.sort).to eq(expected)
    expect(generated - catalog.fetch("grants")).to be_empty
  end
end
