require "rails_helper"

RSpec.describe "Trace context propagation", type: :request do
  let(:trace_id) { "a" * 32 }
  let(:parent_id) { "b" * 16 }

  def page_props
    JSON.parse(response.body[/<script[^>]*data-page="app"[^>]*>(.*?)<\/script>/m, 1])
  end

  it "accepts a valid sampled traceparent and forwards it upstream with a fresh parent id" do
    stub = stub_request(:get, "http://localhost:4000/forbidden")
           .with(headers: { "traceparent" => /\A00-#{trace_id}-[0-9a-f]{16}-01\z/ })
           .to_return(status: 403, body: { error: { code: "resource.forbidden" } }.to_json,
                      headers: { "Content-Type" => "application/json" })
    lines = capture_lograge do
      get "/en/dummy/widgets/upstream_forbidden", headers: auth_headers.merge(
        "X-Request-Id" => "request-trace",
        "traceparent" => "00-#{trace_id}-#{parent_id}-01"
      )
    end

    expect(stub).to have_been_requested.once
    expect(page_props.dig("props", "trace", "traceId")).to eq(trace_id)
    expect(lines.length).to eq(1)
    expect(lines.first["trace_id"]).to eq(trace_id)
    expect(lines.first["upstream_calls"]).to eq("api" => 1)
  end

  it "forwards the sampled bit only, never another flag bit" do
    stub = stub_request(:get, "http://localhost:4000/forbidden")
           .with(headers: { "traceparent" => /\A00-#{trace_id}-[0-9a-f]{16}-00\z/ })
           .to_return(status: 403, body: { error: { code: "resource.forbidden" } }.to_json,
                      headers: { "Content-Type" => "application/json" })

    get "/en/dummy/widgets/upstream_forbidden", headers: auth_headers.merge(
      "traceparent" => "00-#{trace_id}-#{parent_id}-02"
    )

    expect(stub).to have_been_requested.once
  end

  it "starts a new trace for every hostile header and never logs or echoes it" do
    hostile = {
      "uppercase hex" => "00-#{trace_id.upcase}-#{parent_id}-01",
      "version ff" => "ff-#{trace_id}-#{parent_id}-01",
      "zero trace id" => "00-#{'0' * 32}-#{parent_id}-01",
      "zero parent id" => "00-#{trace_id}-#{'0' * 16}-01",
      "short field" => "00-#{trace_id}-#{parent_id}-1",
      "version 00 with a trailing field" => "00-#{trace_id}-#{parent_id}-01-extra",
      "request id is not a trace" => "not-a-traceparent"
    }
    traces = []

    hostile.each do |label, value|
      raw = raw_lograge_output do
        get "/en", headers: auth_headers.merge(
          "X-Request-Id" => "request-hostile",
          "traceparent" => value
        )
      end

      trace = page_props.dig("props", "trace", "traceId")
      expect(trace).to match(/\A[0-9a-f]{32}\z/), label
      expect(trace).not_to eq("0" * 32), label
      expect(trace).not_to eq(trace_id), label
      expect(raw).not_to include(value), label
      expect(JSON.parse(raw.lines.first)["trace_id"]).to eq(trace), label
      expect(JSON.parse(raw.lines.first)["request_id"]).to eq("request-hostile"), label
      traces << trace
    end

    expect(traces.uniq.length).to eq(hostile.length)
  end

  it "keeps the incoming trace id on a 413 from the body limit" do
    post "/core/client_errors", params: "x" * (64 * 1024 + 1),
         headers: { "Content-Type" => "application/json", "traceparent" => "00-#{trace_id}-#{parent_id}-01" }

    body = JSON.parse(response.body).fetch("error")
    expect(response).to have_http_status(:content_too_large)
    expect(body["traceId"]).to eq(trace_id)
  end
end
