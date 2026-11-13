require "rails_helper"

RSpec.describe "Downloads", type: :request do
  it "streams the body with attachment headers and a sanitized filename" do
    get "/en/dummy/download", headers: auth_headers

    expect(response).to have_http_status(:ok)
    expect(response.body).to eq("hello world")
    expect(response.headers["Content-Disposition"]).to include("attachment")
    expect(response.headers["Content-Disposition"]).to include("report.txt")
    expect(response.headers["Cache-Control"]).to include("no-store")
    expect(response.headers["X-Content-Type-Options"]).to eq("nosniff")
    expect(Rafelo::Core::AuditEvent.where(event: "download", outcome: "success").count).to eq(1)
  end

  it "answers the error page before the first byte when the upstream fails" do
    get "/en/dummy/download_failure", headers: auth_headers

    expect(response).to have_http_status(:service_unavailable)
    expect(response.headers["Content-Disposition"]).to be_nil
    expect(response.body).to include("upstream.unavailable")
    expect(Rafelo::Core::AuditEvent.where(event: "download", outcome: "failure").count).to eq(1)
  end

  it "audits an overflow after the first byte as a failure" do
    get "/en/dummy/download_overflow", headers: auth_headers

    expect(Rafelo::Core::AuditEvent.where(event: "download", outcome: "failure").count).to eq(1)
  end

  it "streams more chunks than the bounded queue holds without dropping any" do
    get "/en/dummy/download_many", headers: auth_headers

    expect(response).to have_http_status(:ok)
    expect(response.body.lines.length).to eq(20)
    expect(response.body.lines.last).to eq("chunk-19\n")
  end

  it "answers a 403 raised inside a download source without a second audit row" do
    get "/en/dummy/download_forbidden", headers: auth_headers

    expect(response).to have_http_status(:forbidden)
    expect(response.headers["Content-Disposition"]).to be_nil
    expect(Rafelo::Core::AuditEvent.where(event: "download", outcome: "failure").count).to eq(1)
    expect(Rafelo::Core::AuditEvent.count).to eq(1)
  end

  it "answers unavailable when the per-process download cap is full" do
    allow(Rafelo::Core::DownloadLimiter).to receive(:acquire).and_return(false)

    get "/en/dummy/download", headers: auth_headers

    expect(response).to have_http_status(:service_unavailable)
    expect(response.body).to include("upstream.unavailable")
    expect(response.headers["Content-Disposition"]).to be_nil
  end
end
