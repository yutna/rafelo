require "rails_helper"

RSpec.describe "Authorization denial and grant freshness", type: :request do
  let(:viewer) { Struct.new(:id, :name).new(7, "Ada") }

  it "audits a read denial and re-fetches stale grants once on the next request" do
    session, token = Rafelo::Core::Session.start(
      viewer: viewer, access_token: "access", refresh_token: "refresh",
      access_expires_at: 5.minutes.from_now, grants: [ "billing:invoice:read" ]
    )
    cookie = "session_token=#{token}"
    stub_upstream(:get, "/forbidden", fixture: "errors/403.json", status: 403, base_url: "http://localhost:4000")
    stub_upstream(:post, "/auth/refresh", fixture: "auth/refresh.json", base_url: "http://localhost:4000")

    get "/en/dummy/widgets/upstream_forbidden", headers: { "Cookie" => cookie }

    expect(response).to have_http_status(:forbidden)
    expect(Rafelo::Core::AuditEvent.where(event: "authorization", outcome: "failure").count).to eq(1)
    expect(session.reload.grants_stale?).to be(true)

    get "/en", headers: { "Cookie" => cookie }

    expect(response).to have_http_status(:ok)
    expect(a_request(:post, "http://localhost:4000/auth/refresh")).to have_been_made.once
    expect(session.reload.permission_grants).to include("billing:invoice:create")
  end
end
