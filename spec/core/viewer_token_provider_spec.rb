require "rails_helper"

RSpec.describe Rafelo::Core::ViewerTokenProvider do
  let(:viewer) { Struct.new(:id, :name).new(7, "Ada") }

  after { Rafelo::Core::Current.reset }

  it "refreshes a locally fresh session after a 401 and resends with the new token" do
    session, = Rafelo::Core::Session.start(
      viewer: viewer,
      access_token: "old-access",
      refresh_token: "old-refresh",
      access_expires_at: 5.minutes.from_now,
      grants: [ "billing:invoice:read" ]
    )
    Rafelo::Core::Current.session = session
    Rafelo::Core::Current.request_id = "request-1"
    Rafelo::Core::Current.trace_id = "trace-1"
    Rafelo::Core::Current.call_budget = Rafelo::Core::CallBudget.new(api: 3)
    stub_upstream(:post, "/auth/refresh", fixture: "auth/refresh.json", base_url: "http://localhost:4000")
    old = stub_request(:get, "http://upstream.test/invoices")
      .with(headers: { "Authorization" => "Bearer old-access" })
      .to_return(status: 401, body: "{}")
    fresh = stub_request(:get, "http://upstream.test/invoices")
      .with(headers: { "Authorization" => "Bearer fresh-access" })
      .to_return(status: 200, body: '{"ok":true}')
    config = Rails.application.config.x.upstreams.fetch(:api).with(base_url: "http://upstream.test")
    client = Rafelo::Core::UpstreamClient.new(
      name: :api, config: config, token_provider: described_class.new(session),
      budget: Rafelo::Core::Current.call_budget, request_id: "request-1", trace_id: "trace-1"
    )

    expect(client.get("invoices").status).to eq(200)
    expect(session.reload.access_token).to eq("fresh-access")
    expect(old).to have_been_requested.once
    expect(fresh).to have_been_requested.once
  end
end
