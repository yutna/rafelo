require "rails_helper"

RSpec.describe "Downloads", type: :request do
  it "streams the body with attachment headers and a sanitized filename" do
    get "/en/dummy/download"

    expect(response).to have_http_status(:ok)
    expect(response.body).to eq("hello world")
    expect(response.headers["Content-Disposition"]).to include("attachment")
    expect(response.headers["Content-Disposition"]).to include("report.txt")
    expect(response.headers["Cache-Control"]).to include("no-store")
    expect(response.headers["X-Content-Type-Options"]).to eq("nosniff")
    expect(Rafelo::Core::AuditEvent.where(event: "download", outcome: "success").count).to eq(1)
  end

  it "answers the error page before the first byte when the upstream fails" do
    get "/en/dummy/download_failure"

    expect(response).to have_http_status(:service_unavailable)
    expect(response.headers["Content-Disposition"]).to be_nil
    expect(response.body).to include("upstream.unavailable")
    expect(Rafelo::Core::AuditEvent.where(event: "download", outcome: "failure").count).to eq(1)
  end
end
