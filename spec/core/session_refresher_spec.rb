require "rails_helper"

RSpec.describe Rafelo::Core::SessionRefresher do
  let(:viewer) { Struct.new(:id, :name).new(7, "Ada") }
  let(:result) do
    Rafelo::Core::AuthGateway::Result.new(
      viewer: viewer,
      access_token: "winner-access",
      refresh_token: "winner-refresh",
      access_expires_at: 5.minutes.from_now,
      grants: [ "billing:invoice:create" ]
    )
  end

  def start_session
    session, = Rafelo::Core::Session.start(
      viewer: viewer,
      access_token: "old-access",
      refresh_token: "old-refresh",
      access_expires_at: 10.seconds.from_now,
      grants: [ "billing:invoice:read" ]
    )
    session.update_column(:grants_refreshed_at, 10.minutes.ago)
    session
  end

  it "returns the successor token when another caller wins the refresh race" do
    session = start_session
    gateway = Class.new do
      def initialize(session_id:, result:)
        @session_id = session_id
        @result = result
      end

      def refresh(refresh_token:)
        successor = Rafelo::Core::Session.find(@session_id)
        successor.update_column(:refreshing_since, 2.minutes.ago)
        successor.reload
        version = successor.claim_refresh!(timeout: 15)
        successor.complete_refresh!(
          version: version,
          access_token: "successor-access",
          refresh_token: "successor-refresh",
          access_expires_at: 5.minutes.from_now
        )
        successor.replace_grants!([ "billing:invoice:read" ], generation: successor.grants_generation)
        @result
      end
    end.new(session_id: session.id, result: result)

    token = described_class.new(session: session, gateway: gateway, timeout: 0).call

    expect(token).to eq("successor-access")
    expect(Rafelo::Core::Session.exists?(session.id)).to be(true)
    expect(Rafelo::Core::Session.find(session.id).access_token).to eq("successor-access")
  end

  it "maps a session deleted during refresh to auth.expired" do
    session = start_session
    gateway = Class.new do
      def initialize(session_id:, result:)
        @session_id = session_id
        @result = result
      end

      def refresh(refresh_token:)
        Rafelo::Core::Session.find(@session_id).destroy
        @result
      end
    end.new(session_id: session.id, result: result)

    expect do
      described_class.new(session: session, gateway: gateway, timeout: 0).call
    end.to raise_error(Rafelo::Core::ApplicationError) { |error| expect(error.code).to eq("auth.expired") }
  end
end
