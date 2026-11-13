require "rails_helper"

RSpec.describe Rafelo::Core::IdempotencyClaim do
  it "derives the key from the viewer and token, not the payload" do
    viewer = Struct.new(:id, :name).new(7, "Ada")
    session, = Rafelo::Core::Session.start(
      viewer: viewer, access_token: "a", refresh_token: "r", access_expires_at: 5.minutes.from_now
    )
    token = Rafelo::Core::FormToken.issue(session_id: session.id)
    controller = double("controller", response: double(location: "/en/done"))
    allow(controller).to receive(:redirect_after_write)
    allow(controller).to receive(:redirect_to)

    Rafelo::Core::Current.session = session
    first = described_class.call(controller, token: token, payload: { name: "ada" }, back: "/en/form") { :ok }
    second = described_class.call(controller, token: token, payload: { name: "grace" }, back: "/en/form") { :ok }

    expect(first).to eq(:performed)
    expect(second).to eq(:handled)
    expect(controller).to have_received(:redirect_after_write).once
  ensure
    Rafelo::Core::Current.reset
  end

  it "keeps the row retention at least one session lifetime plus a margin" do
    config = Rails.application.config.x
    expect(config.idempotency.retention_seconds)
      .to be >= (config.sessions.absolute_timeout_seconds + 60)
  end
  it "records an ambiguous failure as unknown without an idempotent upstream" do
    expect(claim_outcome(upstream_idempotent: false)).to eq("unknown")
  end

  it "records an ambiguous failure as failed for an idempotent upstream" do
    expect(claim_outcome(upstream_idempotent: true)).to eq("failed")
  end

  def claim_outcome(upstream_idempotent:)
    viewer = Struct.new(:id, :name).new(7, "Ada")
    session, = Rafelo::Core::Session.start(
      viewer: viewer, access_token: "a", refresh_token: "r", access_expires_at: 5.minutes.from_now
    )
    token = Rafelo::Core::FormToken.issue(session_id: session.id)
    controller = double("controller", response: double(location: "/en/done"))
    allow(controller).to receive(:redirect_after_write)
    allow(controller).to receive(:redirect_to)
    Rafelo::Core::Current.session = session

    expect do
      described_class.call(
        controller, token: token, payload: { name: "ada" }, back: "/en/form",
        upstream_idempotent: upstream_idempotent
      ) { raise Rafelo::Core::ApplicationError.new("upstream.timeout") }
    end.to raise_error(Rafelo::Core::ApplicationError)

    Rafelo::Core::IdempotencyKey.find_by(token_digest: Digest::SHA256.hexdigest(token)).status
  ensure
    Rafelo::Core::Current.reset
  end
end
