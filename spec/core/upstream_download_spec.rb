require "rails_helper"

RSpec.describe "Upstream download streaming" do
  let(:token) { Struct.new(:token, :service?).new("secret", false) }
  let(:config) do
    Rafelo::Core::UpstreamConfig.new(
      base_url: "http://upstream.test",
      open_timeout: 1, read_timeout: 2, write_timeout: 1,
      max_concurrent_calls: 2, max_response_bytes: 100,
      retry_budget: 0, idempotency_keys: false,
      service_token_gateways: [], breaker: { failure_threshold: 100, cool_off: 1 }
    )
  end
  let(:client) do
    Rafelo::Core::UpstreamClient.new(name: :download, config: config, token_provider: token)
  end

  it "yields body chunks after checking the status" do
    stub_request(:get, "http://upstream.test/report").to_return(status: 200, body: "hello world")
    chunks = []

    client.stream(:get, "report") { |chunk| chunks << chunk }

    expect(chunks.join).to eq("hello world")
  end

  it "rejects an error status before yielding a byte" do
    stub_request(:get, "http://upstream.test/report").to_return(status: 500, body: "boom")
    chunks = []

    expect do
      client.stream(:get, "report") { |chunk| chunks << chunk }
    end.to raise_error(Rafelo::Core::ApplicationError)

    expect(chunks).to be_empty
  end

  it "rejects a body over the download cap before yielding a byte" do
    stub_request(:get, "http://upstream.test/report").to_return(status: 200, body: "x" * 200)
    chunks = []

    expect do
      client.stream(:get, "report", max_bytes: 100) { |chunk| chunks << chunk }
    end.to raise_error(Rafelo::Core::ApplicationError)

    expect(chunks).to be_empty
  end
end

RSpec.describe Rafelo::Core::DownloadLimiter do
  after { described_class.reset! }

  it "admits only the configured number of concurrent downloads" do
    first = described_class.acquire
    second = described_class.acquire

    expect(first).to be_truthy
    expect(second).to be_truthy
    expect(described_class.acquire).to be(false)

    described_class.release(first)
    expect(described_class.acquire).to be_truthy
  end
end
