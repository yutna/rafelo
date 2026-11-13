require "rails_helper"

RSpec.describe "Trace ids on early errors", type: :request do
  let(:trace_id) { "a" * 32 }
  let(:headers) do
    {
      "X-Request-Id" => "request-early",
      "traceparent" => "00-#{trace_id}-#{'b' * 16}-01"
    }
  end
  let(:forwarded) { [] }

  before do
    allow(Rafelo::Core::ReportingService).to receive(:capture) do |_error, handled:, severity:, context:|
      forwarded << { handled: handled, severity: severity, context: context }
    end
  end

  it "reports a handled sign-in failure with the ids" do
    stub_upstream(:post, "/auth/sign_in", fixture: "errors/401.json", status: 401, base_url: "http://localhost:4000")

    post "/en/sign_in", params: { email: "a@example.test", password: "wrong" }, headers: headers

    expect(response).to have_http_status(:unauthorized)
    context = forwarded.last.fetch(:context).stringify_keys
    expect(context["code"]).to eq("auth.expired")
    expect(context["request_id"]).to eq("request-early")
    expect(context["trace_id"]).to eq(trace_id)
  end

  it "keeps the ids on a throttled error page, log line and report" do
    stub_upstream(:post, "/auth/sign_in", fixture: "errors/401.json", status: 401, base_url: "http://localhost:4000")

    raw = raw_lograge_output do
      11.times do
        post "/th/sign_in", params: { email: "a@example.test", password: "wrong" }, headers: headers
      end
    end

    expect(response).to have_http_status(:too_many_requests)
    page = JSON.parse(response.body[/<script[^>]*data-page="app"[^>]*>(.*?)<\/script>/m, 1])
    expect(page.dig("props", "trace", "requestId")).to eq("request-early")
    expect(page.dig("props", "trace", "traceId")).to eq(trace_id)

    line = JSON.parse(raw.lines.last)
    expect(line["request_id"]).to eq("request-early")
    expect(line["trace_id"]).to eq(trace_id)

    throttled = forwarded.reverse.find { |entry| entry[:context]["code"] == "request.throttled" }
    expect(throttled).to be_present
    expect(throttled[:context]).to include(
      "request_id" => "request-early",
      "trace_id" => trace_id
    )
  end
end
