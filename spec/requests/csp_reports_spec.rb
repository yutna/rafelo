require "rails_helper"

RSpec.describe "CSP reports", type: :request do
  before { Rafelo::Core::Metrics.reset! }

  def report_headers
    { "Content-Type" => "application/csp-report" }
  end

  def decoded_log_lines
    lines = []
    allow(Rails.logger).to receive(:info) do |line|
      next unless line.start_with?("{")

      parsed = JSON.parse(line)
      lines << parsed if parsed["event"] == "csp_report"
    end
    yield
    lines
  end

  it "accepts a legacy CSP report without a session or CSRF token and logs one allow-listed line", :csrf do
    payload = {
      "csp-report" => {
        "document-uri" => "https://app.test/en/invoices?page=2",
        "violated-directive" => "script-src",
        "blocked-uri" => "https://evil.test/payload.js",
        "source-file" => "https://app.test/assets/application.js",
        "line-number" => 42
      }
    }

    lines = decoded_log_lines do
      post "/core/csp_reports", params: payload.to_json, headers: report_headers
    end

    expect(response).to have_http_status(:no_content)
    expect(lines.length).to eq(1)
    line = lines.first
    expect(line.keys).to contain_exactly(
      "event", "directive", "blocked_origin", "document_path", "source_origin", "source_line", "release"
    )
    expect(line["event"]).to eq("csp_report")
    expect(line["directive"]).to eq("script-src")
    expect(line["blocked_origin"]).to eq("https://evil.test")
    expect(line["document_path"]).to eq("/en/invoices")
    expect(line["source_origin"]).to eq("https://app.test")
    expect(line["source_line"]).to eq(42)
    expect(line["release"]).to start_with("#{Rafelo::Core::Release.version}:")
    expect(Rafelo::Core::Metrics.text).to include(
      'rafelo_csp_reports_total{blocked_origin="external",directive="script-src"} 1'
    )
  end

  it "accepts the Reporting API array and logs each report" do
    payload = [
      {
        "type" => "csp-violation",
        "body" => {
          "documentURL" => "https://app.test/th/invoices?x=1",
          "effectiveDirective" => "style-src",
          "blockedURL" => "inline",
          "sourceFile" => "https://app.test/app.css",
          "lineNumber" => 10
        }
      },
      {
        "type" => "csp-violation",
        "body" => {
          "documentURL" => "https://app.test/en",
          "effectiveDirective" => "img-src",
          "blockedURL" => "data:",
          "sourceFile" => "https://app.test/app.js",
          "lineNumber" => 7
        }
      }
    ]

    lines = decoded_log_lines do
      post "/core/csp_reports", params: payload.to_json, headers: report_headers
    end

    expect(response).to have_http_status(:no_content)
    expect(lines.map { |line| line["directive"] }).to eq([ "style-src", "img-src" ])
    expect(lines.map { |line| line["blocked_origin"] }).to eq([ "inline", "data:" ])
    expect(lines.map { |line| line["document_path"] }).to eq([ "/th/invoices", "/en" ])
  end

  it "accepts hostile but legitimate report values without a 500" do
    blocked = [
      "javascript:alert(1)", "data:text/javascript,alert(1)",
      "blob:https://app.test/uuid", "about:blank", "//evil.test/x", "/app.js"
    ]
    lines = decoded_log_lines do
      blocked.each do |value|
        payload = {
          "csp-report" => {
            "blocked-uri" => value,
            "violated-directive" => "script-src",
            "document-uri" => "https://app.test/en?x=1",
            "source-file" => "/app.js",
            "line-number" => 1
          }
        }
        post "/core/csp_reports", params: payload.to_json, headers: report_headers
        expect(response).to have_http_status(:no_content)
      end
    end
    expect(lines.map { |line| line["blocked_origin"] }).to contain_exactly(
      "javascript:", "data:", "blob:", "about:", "unknown", "unknown"
    )
    expect(lines.map { |line| line["document_path"] }.uniq).to eq([ "/en" ])
    expect(lines.map { |line| line["source_origin"] }.uniq).to eq([ "unknown" ])
  end

  it "ignores an empty report instead of logging an empty line" do
    lines = decoded_log_lines do
      post "/core/csp_reports", params: "{}", headers: report_headers
    end

    expect(response).to have_http_status(:no_content)
    expect(lines).to be_empty
  end

  it "rejects a body that is not JSON" do
    post "/core/csp_reports", params: "not-json", headers: report_headers

    expect(response).to have_http_status(:bad_request)
  end

  it "throttles reports per IP" do
    limits = Rafelo::Core::CspReportsController.throttle_limits.fetch(:create)
    expect(limits).to include(hash_including(name: "csp_reports/ip", to: 60))
  end
end
