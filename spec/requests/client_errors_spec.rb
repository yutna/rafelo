require "rails_helper"

RSpec.describe "Client error reports", :csrf, type: :request do
  let(:trace_id) { "a" * 32 }
  let(:forwarded) { [] }

  before do
    allow(Rafelo::Core::ReportingService).to receive(:capture) do |_error, handled:, severity:, context:|
      forwarded << { handled: handled, severity: severity, context: context }
    end
  end

  def csrf_headers
    get "/en/sign_in"
    session_cookie = Array(response.headers["Set-Cookie"]).flat_map { |header| header.split("\n") }
      .find { |value| value.start_with?("rafelo_session=") }
    {
      "Content-Type" => "application/json",
      "X-CSRF-Token" => csrf_token_from_response,
      "Cookie" => session_cookie&.split(";")&.first
    }.compact
  end

  def report_payload(overrides = {})
    {
      message: "boom",
      stack: "at Component",
      page: "orders/index",
      path: "/en/orders?token=hidden",
      release: "a" * 40,
      requestId: "request-1",
      traceId: trace_id
    }.merge(overrides)
  end

  it "accepts a scrubbed report without returning viewer data" do
    headers = csrf_headers

    post "/core/client_errors",
         params: report_payload(
           message: "mail ada@example.test with a JWT eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiI3In0.signature",
           stack: "Authorization: Bearer secret-token",
           page: "orders/#{'a' * 40}",
           path: "/en/orders/#{'b' * 40}?token=secret",
           release: "f" * 39
         ).to_json,
         headers: headers

    expect(response).to have_http_status(:no_content)
    expect(response.body).to be_empty
    context = forwarded.fetch(0).fetch(:context).stringify_keys
    expect(context.keys).to contain_exactly(
      "message", "stack", "page", "path", "release", "request_id", "trace_id"
    )
    expect(context["message"]).to include("[FILTERED]")
    expect(context["stack"]).to eq("Authorization: [FILTERED]")
    expect(context["page"]).to include("[FILTERED]")
    expect(context["path"]).to eq("/en/orders/[FILTERED]")
    expect(context["release"]).to eq("unknown")
    expect(context["request_id"]).to eq("request-1")
    expect(context["trace_id"]).to eq(trace_id)
    expect(context.to_json).not_to include("viewer", "props", "headers", "cookie")
  end

  it "requires a CSRF token" do
    post "/core/client_errors",
         params: report_payload.to_json,
         headers: { "Content-Type" => "application/json" }

    expect(response).to have_http_status(:unprocessable_content)
  end

  it "rejects a body over its cap before Rails parses it" do
    post "/core/client_errors",
         params: "x" * (8 * 1024 + 1),
         headers: { "Content-Type" => "application/json" }

    expect(response).to have_http_status(:content_too_large)
  end

  it "limits one session separately from the IP" do
    headers = csrf_headers
    headers["Cookie"] = [ headers["Cookie"], sign_in_cookie(viewer_id: 91) ].compact.join("; ")

    10.times do
      post "/core/client_errors", params: report_payload.to_json, headers: headers
      expect(response).to have_http_status(:no_content)
    end

    post "/core/client_errors", params: report_payload.to_json, headers: headers
    expect(response).to have_http_status(:too_many_requests)
  end

  it "keeps the IP limit when each request has a fresh session" do
    headers = csrf_headers

    30.times do |index|
      post "/core/client_errors",
           params: report_payload(requestId: "request-#{index}").to_json,
           headers: headers.merge(
             "Cookie" => [ headers["Cookie"], sign_in_cookie(viewer_id: 1_000 + index) ].compact.join("; ")
           )
      expect(response).to have_http_status(:no_content)
    end

    post "/core/client_errors",
         params: report_payload(requestId: "request-final").to_json,
         headers: headers.merge(
           "Cookie" => [ headers["Cookie"], sign_in_cookie(viewer_id: 2_000) ].compact.join("; ")
         )
    expect(response).to have_http_status(:too_many_requests)
  end
end
