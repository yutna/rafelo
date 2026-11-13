require "rails_helper"

RSpec.describe Rafelo::Core::LogPayload do
  let(:trace_id) { "a" * 32 }

  def request_for(path)
    ActionDispatch::Request.new(Rack::MockRequest.env_for(path))
  end

  it "uses an HMAC viewer id that is neither the raw id nor its bare SHA-256" do
    opaque = described_class.opaque_viewer("7")

    expect(opaque).to match(/\A[0-9a-f]{16}\z/)
    expect(opaque).not_to eq("7")
    expect(opaque).not_to eq(Digest::SHA256.hexdigest("7"))
    expect(described_class.opaque_viewer("7")).to eq(opaque)
    expect(described_class.opaque_viewer("8")).not_to eq(opaque)
  end

  it "builds exactly the allow-listed keys" do
    request = request_for("/en?token=secret#fragment")
    collector = Rafelo::Core::RequestLog.new
    collector.record_sql({ name: "Session Load" })
    collector.record_upstream({ name: :api }, 4.5)
    env = request.env
    env["rafelo.request_id"] = "request-1"
    env["rafelo.trace_id"] = trace_id
    env["rafelo.request_log"] = collector
    env["rafelo.page"] = "home/index"
    env["rafelo.props_bytes"] = 123
    env["rafelo.log.viewer"] = "viewer-hash"
    env["rafelo.locale"] = "en"

    payload = described_class.new(
      data: { method: "GET", path: "/en", controller: "HomeController", action: "show", status: 200, duration: 12.3, db: 2.1 },
      event_payload: { request: request }
    ).to_h

    expect(payload.keys.map(&:to_s)).to contain_exactly(*described_class::ALLOWED_KEYS)
    expect(payload[:path]).to eq("/en")
    expect(payload[:sql_count]).to eq(1)
    expect(payload[:upstream_calls]).to eq("api" => 1)
    expect(payload[:upstream_time]).to eq("api" => 4.5)
    expect(payload[:viewer]).to eq("viewer-hash")
    expect(payload.to_json).not_to include("secret")
  end
end
