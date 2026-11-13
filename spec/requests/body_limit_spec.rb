require "rails_helper"

RSpec.describe "Core report body limits", type: :request do
  it "rejects a declared body over the cap before Rails parses it" do
    post "/core/client_errors", params: "x" * (64 * 1024 + 1), headers: { "Content-Type" => "application/json" }

    expect(response).to have_http_status(:content_too_large)
    expect(JSON.parse(response.body).dig("error", "code")).to eq("request.entity_too_large")
    expect(response.headers["Cache-Control"]).to include("no-store")
  end

  it "allows a body at the cap through to the router" do
    payload = %({"x":"#{'a' * (64 * 1024 - 8)}"})
    post "/core/csp_reports", params: payload, headers: { "Content-Type" => "application/json" }

    expect(payload.bytesize).to eq(64 * 1024)
    expect(response).to have_http_status(:not_found)
  end
end
