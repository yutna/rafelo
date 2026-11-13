require "rails_helper"

RSpec.describe Rafelo::Core::RestorePreparation do
  it "empties every restored session before traffic" do
    Rafelo::Core::Session.create!(
      token_digest: "restored-session",
      viewer_id: "7",
      expires_at: 1.hour.from_now
    )

    described_class.new.empty_sessions!

    expect(Rafelo::Core::Session.count).to eq(0)
  end
end
