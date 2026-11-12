require "rails_helper"

RSpec.describe Rafelo::Core::UpstreamClient do
  let(:config) do
    Rafelo::Core::UpstreamConfig.new(
      base_url: "http://upstream.test",
      open_timeout: 1,
      read_timeout: 2,
      write_timeout: 2,
      max_concurrent_calls: 2,
      max_response_bytes: 100,
      retry_budget: 0.1,
      idempotency_keys: false,
      breaker: { failure_threshold: 100, cool_off: 1 }
    )
  end
  let(:token) { Struct.new(:token).new("secret") }
  let(:client) do
    described_class.new(name: :api, config: config, token_provider: token,
                        request_id: "request-1", trace_id: "trace-1")
  end

  it "performs a GET with the identity headers" do
    stub = stub_request(:get, "http://upstream.test/invoices")
           .with(headers: { "Authorization" => "Bearer secret", "X-Request-Id" => "request-1" })
           .to_return(status: 200, body: '{"ok":true}')

    response = client.get("/invoices")

    expect(response.body).to eq('{"ok":true}')
    expect(stub).to have_been_requested.once
  end

  it "refuses a gateway-supplied identity header" do
    expect { client.get("/invoices", headers: { "Authorization" => "other" }) }
      .to raise_error(ArgumentError, /may not set/)
  end

  it "maps each upstream status to its catalog code" do
    {
      401 => "auth.expired",
      403 => "auth.forbidden",
      404 => "resource.not_found",
      409 => "resource.conflict",
      413 => "validation.failed",
      422 => "validation.failed",
      429 => "upstream.unavailable",
      500 => "upstream.unavailable",
      400 => "unexpected"
    }.each do |status, code|
      stub_request(:get, "http://upstream.test/status").to_return(status: status, body: "{}")
      expect { client.get("/status") }.to raise_error(Rafelo::Core::ApplicationError) { |error| expect(error.code).to eq(code) }
    end
  end

  it "retries a GET once on a 503" do
    stub_request(:get, "http://upstream.test/retry")
      .to_return({ status: 503, body: "{}" }, { status: 200, body: '{"ok":true}' })

    expect(client.get("/retry").body).to eq('{"ok":true}')
  end

  it "refuses a response over the byte cap" do
    stub_request(:get, "http://upstream.test/large").to_return(status: 200, body: "x" * 101)

    expect { client.get("/large") }.to raise_error(Rafelo::Core::ApplicationError) { |error| expect(error.code).to eq("unexpected") }
  end

  it "opens the breaker after repeated failures" do
    short = config.with(breaker: { failure_threshold: 1, cool_off: 60 })
    breaker_client = described_class.new(name: :breaker, config: short, token_provider: token)
    stub_request(:get, "http://upstream.test/fail").to_return(status: 500, body: "{}")

    expect { breaker_client.get("/fail") }.to raise_error(Rafelo::Core::ApplicationError)
    expect { breaker_client.get("/fail") }.to raise_error(Rafelo::Core::ApplicationError) { |error| expect(error.code).to eq("upstream.circuit_open") }
  end
end
