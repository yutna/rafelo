require "rails_helper"

RSpec.describe Rafelo::Core::TraceMiddleware do
  let(:trace_id) { "a" * 32 }
  let(:parent_id) { "b" * 16 }

  describe ".parse" do
    it "accepts a sampled W3C traceparent" do
      expect(described_class.parse("00-#{trace_id}-#{parent_id}-01"))
        .to eq(trace_id: trace_id, sampled: true)
    end

    it "keeps only the sampled bit from the flags" do
      expect(described_class.parse("00-#{trace_id}-#{parent_id}-03"))
        .to eq(trace_id: trace_id, sampled: true)
      expect(described_class.parse("00-#{trace_id}-#{parent_id}-02"))
        .to eq(trace_id: trace_id, sampled: false)
    end

    it "reads a future version by its first four fields" do
      expect(described_class.parse("01-#{trace_id}-#{parent_id}-01-extra"))
        .to eq(trace_id: trace_id, sampled: true)
    end

    it "rejects every hostile or malformed value" do
      [
        "00-#{trace_id.upcase}-#{parent_id}-01",
        "ff-#{trace_id}-#{parent_id}-01",
        "00-#{'0' * 32}-#{parent_id}-01",
        "00-#{trace_id}-#{'0' * 16}-01",
        "00-#{trace_id}-#{parent_id}-1",
        "00-#{trace_id}-#{parent_id}-01-extra",
        "01-#{trace_id}-#{parent_id}",
        "trace-home",
        ""
      ].each do |value|
        expect(described_class.parse(value)).to be_nil, value
      end
    end
  end

  it "stores a valid trace and its sampled bit in the env" do
    env = { "action_dispatch.request_id" => "request-1", "HTTP_TRACEPARENT" => "00-#{trace_id}-#{parent_id}-01" }
    app = ->(inner) { [ 200, {}, [ inner["rafelo.trace_id"] ] ] }

    status, _headers, body = described_class.new(app).call(env)

    expect(status).to eq(200)
    expect(body.first).to eq(trace_id)
    expect(env["rafelo.request_id"]).to eq("request-1")
    expect(env["rafelo.trace_sampled"]).to be(true)
  end

  it "starts a fresh non-zero trace for a hostile header without echoing it" do
    hostile = "ff-#{trace_id}-#{parent_id}-01"
    env = { "action_dispatch.request_id" => "request-1", "HTTP_TRACEPARENT" => hostile }
    app = ->(inner) { [ 200, {}, [ inner["rafelo.trace_id"] ] ] }

    _status, _headers, body = described_class.new(app).call(env)

    expect(body.first).to match(/\A[0-9a-f]{32}\z/)
    expect(body.first).not_to eq("0" * 32)
    expect(body.first).not_to eq(trace_id)
    expect(env["rafelo.trace_sampled"]).to be(false)
  end
end
