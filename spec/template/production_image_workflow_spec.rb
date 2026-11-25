# frozen_string_literal: true

require "rails_helper"
require "yaml"

# The production-image job boots the final image with throwaway credentials.
# They must never touch the tracked config/credentials/production.yml.enc
# (#432, BE-08, SEC-07).
RSpec.describe "Production image workflow" do
  let(:jobs) { YAML.safe_load_file(Rails.root.join(".github/workflows/ci.yml"), aliases: true).fetch("jobs") }
  let(:steps) { jobs.fetch("production-image").fetch("steps") }

  def step(name)
    steps.find { |candidate| candidate["name"] == name }
  end

  it "encrypts the throwaway credentials outside the workspace" do
    writer = step("Write throwaway production credentials")

    expect(writer).not_to be_nil
    expect(writer.fetch("run")).to include('config_path: "/tmp/rafelo-production.yml.enc"')
    expect(writer.fetch("run")).not_to include('config_path: "config/credentials/')
  end

  it "mounts the temporary credentials into both database and boot containers" do
    mount = "-v /tmp/rafelo-production.yml.enc:/rails/config/credentials/production.yml.enc:ro"

    [ "Prepare the image database", "Boot the production image and check /up" ].each do |name|
      expect(step(name).fetch("run")).to include(mount)
    end
  end

  it "proves the tracked credentials file is unchanged after the build" do
    names = steps.map { |candidate| candidate["name"] }

    expect(step("Verify the tracked production credentials are untouched").fetch("run"))
      .to include("git diff --exit-code -- config/credentials/production.yml.enc")
    expect(names.index("Write throwaway production credentials"))
      .to be < names.index("Build the production image")
    expect(names.index("Verify the tracked production credentials are untouched"))
      .to be > names.index("Build the production image")
  end
end
