require "rails_helper"
require "yaml"

RSpec.describe Rafelo::Core::IdempotencySweepJob do
  it "deletes expired keys in batches" do
    expired = Rafelo::Core::IdempotencyKey.create!(
      token_digest: "expired", viewer_id: "7", payload_digest: "x", expires_at: 1.hour.ago
    )
    live = Rafelo::Core::IdempotencyKey.create!(
      token_digest: "live", viewer_id: "7", payload_digest: "x", expires_at: 1.hour.from_now
    )

    described_class.perform_now

    expect(Rafelo::Core::IdempotencyKey.exists?(expired.id)).to be(false)
    expect(Rafelo::Core::IdempotencyKey.exists?(live.id)).to be(true)
  end

  it "is scheduled hourly in production" do
    config = YAML.load_file(Rails.root.join("config/recurring.yml"), aliases: true)
    sweep = config.dig("production", "idempotency_sweep")

    expect(sweep["class"]).to eq("Rafelo::Core::IdempotencySweepJob")
  end
end
