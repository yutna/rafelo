# frozen_string_literal: true

require "rails_helper"

RSpec.describe Rafelo::Core::LegacyRedirect do
  it "redirects to the target path under the module preserving locale and rest" do
    entry = Rafelo::Core::Modules::Entry.new(
      key: :payments,
      engine: Object,
      path: "/payments",
      permission_prefixes: [ "payments" ],
      legacy_paths: {},
      nav: {},
      flag: nil
    )
    env = Rack::MockRequest.env_for("/en/billing/refunds/5", params: { locale: "en", rest: "5" })
    env["action_dispatch.request.path_parameters"] = { locale: "en", rest: "5" }

    status, headers, body = described_class.new(entry, "/refunds").call(env)

    expect(status).to eq(301)
    expect(headers["Location"]).to eq("/en/payments/refunds/5")
    expect(body.join).to eq("Moved Permanently")
  end
end
