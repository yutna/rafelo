require "rails_helper"

RSpec.describe "Structured request log", type: :request do
  let(:trace_id) { "a" * 32 }

  it "writes one allow-listed JSON line without the query string or parameter values" do
    lines = capture_lograge do
      get "/en?token=super-secret-param", headers: auth_headers.merge(
        "X-Request-Id" => "request-log",
        "traceparent" => "00-#{trace_id}-#{'b' * 16}-01"
      )
    end

    expect(lines.length).to eq(1)
    line = lines.first
    expect(line.keys).to contain_exactly(*Rafelo::Core::LogPayload::ALLOWED_KEYS)
    expect(line["request_id"]).to eq("request-log")
    expect(line["trace_id"]).to eq(trace_id)
    expect(line["method"]).to eq("GET")
    expect(line["path"]).to eq("/en")
    expect(line["controller"]).to eq("HomeController")
    expect(line["action"]).to eq("show")
    expect(line["page"]).to eq("home/index")
    expect(line["status"]).to eq(200)
    expect(line["duration"]).to be_positive
    expect(line["sql_count"]).to be_positive
    expect(line["props_bytes"]).to be_positive
    expect(line["locale"]).to eq("en")
    expect(line["viewer"]).to match(/\A[0-9a-f]{16}\z/)
    expect(line["viewer"]).not_to eq("7")
    expect(line.to_json).not_to include("super-secret-param")
  end

  it "does not log a token-like password from a request body" do
    stub_upstream(:post, "/auth/sign_in", fixture: "auth/sign_in.json", base_url: "http://localhost:4000")

    raw = raw_lograge_output do
      post "/en/sign_in", params: { email: "ada@example.test", password: "super-secret-password" }
    end

    expect(raw).not_to include("super-secret-password")
    expect(raw).not_to include("ada@example.test")
    line = JSON.parse(raw.lines.first)
    expect(line["controller"]).to eq("SessionsController")
    expect(line["page"]).to be_nil
  end
end
