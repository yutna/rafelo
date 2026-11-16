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

  it "allows a CSP report at the cap through to the endpoint" do
    payload = %({"csp-report":{"blocked-uri":"inline","violated-directive":"script-src"}})
    post "/core/csp_reports", params: payload, headers: { "Content-Type" => "application/csp-report" }

    expect(response).to have_http_status(:no_content)
  end

  it "rejects a CSP report over the cap before Rails parses it" do
    post "/core/csp_reports", params: "x" * (64 * 1024 + 1),
         headers: { "Content-Type" => "application/csp-report" }

    expect(response).to have_http_status(:content_too_large)
  end

  it "applies the same cap with a format suffix or a trailing slash" do
    body = "x" * (64 * 1024 + 1)

    [ "/core/csp_reports.json", "/core/csp_reports/", "/core/csp_reports.json?x=1" ].each do |path|
      post path, params: body, headers: { "Content-Type" => "application/csp-report" }

      expect(response).to have_http_status(:content_too_large), "expected 413 for #{path}"
    end
  end

  it "applies the cap to percent-encoded suffixes" do
    body = "x" * (64 * 1024 + 1)

    [ "/core/csp_reports.json%2F", "/core/csp_reports%252F", "/core/csp_reports%3Bfoo",
      "/core/csp_reports%2Ejson", "/core/csp_reports%20" ].each do |path|
      post path, params: body, headers: { "Content-Type" => "application/csp-report" }

      expect(response).to have_http_status(:content_too_large), "expected 413 for #{path}"
    end
  end

  it "does not cap a look-alike path" do
    post "/core/csp_reports_extra", params: "x" * (64 * 1024 + 1),
         headers: { "Content-Type" => "application/csp-report" }

    expect(response).to have_http_status(:not_found)
  end
end
