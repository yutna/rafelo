require "rails_helper"

RSpec.describe "Downloads", type: :request do
  def audit_rows(event, outcome)
    Rafelo::Core::AuditEvent.where(
      request_id: response.headers["X-Request-Id"], event: event, outcome: outcome
    )
  end

  def request_audit_rows
    Rafelo::Core::AuditEvent.where(request_id: response.headers["X-Request-Id"])
  end
  it "streams the body with attachment headers and a sanitized filename" do
    get "/en/dummy/download", headers: auth_headers

    expect(response).to have_http_status(:ok)
    expect(response.body).to eq("hello world")
    expect(response.headers["Content-Disposition"]).to include("attachment")
    expect(response.headers["Content-Disposition"]).to include("report.txt")
    expect(response.headers["Cache-Control"]).to include("no-store")
    expect(response.headers["X-Content-Type-Options"]).to eq("nosniff")
    expect(audit_rows("download", "success").count).to eq(1)
  end

  it "answers the error page before the first byte when the upstream fails" do
    get "/en/dummy/download_failure", headers: auth_headers

    expect(response).to have_http_status(:service_unavailable)
    expect(response.headers["Content-Disposition"]).to be_nil
    expect(response.body).to include("upstream.unavailable")
    expect(audit_rows("download", "failure").count).to eq(1)
  end

  it "audits an overflow after the first byte as a failure" do
    get "/en/dummy/download_overflow", headers: auth_headers

    expect(audit_rows("download", "failure").count).to eq(1)
  end

  it "streams more chunks than the bounded queue holds without dropping any" do
    get "/en/dummy/download_many", headers: auth_headers

    expect(response).to have_http_status(:ok)
    expect(response.body.lines.length).to eq(20)
    expect(response.body.lines.last).to eq("chunk-19\n")
  end

  it "ends a zero-byte download cleanly instead of waiting for the deadline" do
    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    get "/en/dummy/download_empty", headers: auth_headers
    elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started

    expect(response).to have_http_status(:ok)
    expect(response.body).to eq("")
    expect(response.headers["Content-Disposition"]).to include("empty.txt")
    expect(elapsed).to be < 5
    expect(audit_rows("download", "success").count).to eq(1)
  end

  it "answers a 403 raised inside a download source without a second audit row" do
    get "/en/dummy/download_forbidden", headers: auth_headers

    expect(response).to have_http_status(:forbidden)
    expect(response.headers["Content-Disposition"]).to be_nil
    expect(audit_rows("download", "failure").count).to eq(1)
    expect(request_audit_rows.count).to eq(1)
  end

  it "refreshes once after a streamed 401 and streams the body" do
    stub_request(:get, "http://localhost:4000/downloads/1").to_return(
      { status: 401, body: '{"error":"auth.expired"}' },
      { status: 200, body: "hello stream", headers: { "Content-Type" => "text/plain" } }
    )
    stub_upstream(:post, "/auth/refresh", fixture: "auth/refresh.json", base_url: "http://localhost:4000")

    get "/en/dummy/download_streamed", headers: auth_headers

    expect(response).to have_http_status(:ok)
    expect(response.body).to eq("hello stream")
    expect(audit_rows("download", "success").count).to eq(1)
  end

  it "revokes and redirects after a second streamed 401" do
    stub_request(:get, "http://localhost:4000/downloads/1").to_return(
      { status: 401, body: '{"error":"auth.expired"}' },
      { status: 401, body: '{"error":"auth.expired"}' }
    )
    stub_upstream(:post, "/auth/refresh", fixture: "auth/refresh.json", base_url: "http://localhost:4000")

    get "/en/dummy/download_streamed", headers: auth_headers

    expect(response).to have_http_status(:see_other)
    expect(response.location).to include("/en/sign_in")
    expect(audit_rows("download", "failure").count).to eq(1)
  end

  it "answers unavailable when the per-process download cap is full" do
    allow(Rafelo::Core::DownloadLimiter).to receive(:acquire).and_return(false)

    get "/en/dummy/download", headers: auth_headers

    expect(response).to have_http_status(:service_unavailable)
    expect(response.body).to include("upstream.unavailable")
    expect(response.headers["Content-Disposition"]).to be_nil
  end
end
