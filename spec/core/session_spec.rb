require "rails_helper"

RSpec.describe Rafelo::Core::Session do
  let(:viewer) { Struct.new(:id, :name).new(7, "Ada") }

  def start(ttl: 12.hours)
    described_class.start(
      viewer: viewer,
      access_token: "access-secret",
      refresh_token: "refresh-secret",
      access_expires_at: 5.minutes.from_now,
      ttl: ttl
    )
  end

  it "stores only a digest of the cookie token and encrypts the upstream tokens" do
    session, token = start

    expect(session.token_digest).to eq(described_class.digest(token))
    expect(described_class.find_by_token(token)).to eq(session)
    raw = described_class.connection.select_one("SELECT access_token, refresh_token FROM core_sessions WHERE id = #{session.id}")
    expect(raw["access_token"]).not_to eq("access-secret")
    expect(raw["refresh_token"]).not_to eq("refresh-secret")
    expect(session.reload.access_token).to eq("access-secret")
  end

  it "leaves the tokens and digest out of serialization" do
    session, = start
    json = session.as_json

    expect(json.keys).not_to include("access_token", "refresh_token", "token_digest")
    expect(json.to_s).not_to include("access-secret")
  end

  it "lets exactly one caller claim a refresh and clears the claim on completion" do
    session, = start
    first = described_class.find(session.id)
    second = described_class.find(session.id)

    version = first.claim_refresh!(timeout: 15)
    expect(version).to be_a(Integer)
    expect(second.claim_refresh!(timeout: 15)).to be_nil

    first.complete_refresh!(
      version: version,
      access_token: "new-access",
      refresh_token: "new-refresh",
      access_expires_at: 5.minutes.from_now,
      grants: [ "billing:invoice:read" ]
    )
    expect(described_class.find(session.id).access_token).to eq("new-access")
    expect(described_class.find(session.id).refreshing_since).to be_nil
  end

  it "refuses a refresh completion from a stale claim" do
    session, = start
    first = described_class.find(session.id)
    second = described_class.find(session.id)
    stale_version = first.claim_refresh!(timeout: 0)
    first.update_column(:refreshing_since, 2.minutes.ago)
    second.reload
    second.claim_refresh!(timeout: 15)

    expect do
      first.complete_refresh!(
        version: stale_version,
        access_token: "stale-access",
        refresh_token: "stale-refresh",
        access_expires_at: 5.minutes.from_now,
        grants: []
      )
    end.to raise_error(Rafelo::Core::ApplicationError)

    expect(described_class.find(session.id).access_token).to eq("access-secret")
  end

  it "sweeps expired sessions" do
    expired, = start(ttl: -1.minute)
    live, = start

    described_class.sweep

    expect(described_class.exists?(expired.id)).to be(false)
    expect(described_class.exists?(live.id)).to be(true)
  end
end
