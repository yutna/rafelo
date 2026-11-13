require "rails_helper"
require "yaml"

RSpec.describe "Session maintenance" do
  it "schedules the session sweep as a recurring Solid Queue job" do
    config = YAML.load_file(Rails.root.join("config/recurring.yml"), aliases: true)
    sweep = config.dig("production", "session_sweep")

    expect(sweep["class"]).to eq("Rafelo::Core::SessionSweepJob")
    expect(sweep["schedule"]).to be_present
  end
end
