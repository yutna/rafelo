require "rails_helper"
require "yaml"

RSpec.describe "Session maintenance" do
  it "schedules the session sweep as a recurring Solid Queue job" do
    config = YAML.load_file(Rails.root.join("config/recurring.yml"), aliases: true)
    sweep = config.dig("production", "session_sweep")

    expect(sweep["class"]).to eq("Rafelo::Core::SessionSweepJob")
    expect(sweep["schedule"]).to be_present
  end

  it "deletes expired sessions in batches and keeps live ones" do
    expired = Rafelo::Core::Session.create!(
      token_digest: "expired-session",
      viewer_id: "7",
      expires_at: 1.hour.ago
    )
    live = Rafelo::Core::Session.create!(
      token_digest: "live-session",
      viewer_id: "7",
      expires_at: 1.hour.from_now
    )

    Rafelo::Core::SessionSweepJob.perform_now

    expect(Rafelo::Core::Session.exists?(expired.id)).to be(false)
    expect(Rafelo::Core::Session.exists?(live.id)).to be(true)
  end
end
