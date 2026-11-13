require "rails_helper"

RSpec.describe "Core report body limits", type: :request do
  it "rejects a declared body over the cap before Rails parses it" do
    post "/core/client_errors", params: "x" * (64 * 1024 + 1),
         headers: { "Content-Type" => "application/json", "X-Request-Id" => "trace-413" }

    expect(response).to have_http_status(:content_too_large)
    body = JSON.parse(response.body).fetch("error")
    expect(body["code"]).to eq("request.entity_too_large")
    expect(body["requestId"]).to be_present
    expect(body["traceId"]).to match(/\A[0-9a-f]{32}\z/)
    expect(body["traceId"]).not_to eq("trace-413")
    expect(response.headers["Cache-Control"]).to include("no-store")
    expect(response.headers["Permissions-Policy"]).to eq(Rafelo::Core::PermissionsPolicy::VALUE)
    expect(response.headers["X-Content-Type-Options"]).to eq("nosniff")
    expect(response.headers["X-Frame-Options"]).to eq("DENY")
    expect(response.headers["Referrer-Policy"]).to eq("strict-origin-when-cross-origin")
  end

  it "allows a body at the cap through to the router" do
    payload = %({"x":"#{'a' * (64 * 1024 - 8)}"})
    post "/core/csp_reports", params: payload, headers: { "Content-Type" => "application/json" }

    expect(payload.bytesize).to eq(64 * 1024)
    expect(response).to have_http_status(:not_found)
  end
end
