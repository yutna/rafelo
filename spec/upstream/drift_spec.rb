require "rails_helper"
require "yaml"

RSpec.describe "Fixture drift" do
  it "offers every permission key declared by a module manifest" do
    grants = JSON.parse(Rails.root.join("engines/core/spec/fixtures/upstream/api/grants.json").read).fetch("grants")
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
end
