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

  it "refreshes once on a streamed 401 and resends with the new token" do
    refreshing = Class.new do
      attr_reader :refreshes

      def initialize
        @token = "old"
        @refreshes = 0
      end

      def token = @token
      def service? = false

      def refresh!
        @refreshes += 1
        @token = "new"
      end
    end.new
    client = Rafelo::Core::UpstreamClient.new(name: :download, config: config, token_provider: refreshing)
    stub_request(:get, "http://upstream.test/report")
      .with(headers: { "Authorization" => "Bearer old" })
      .to_return(status: 401, body: "{}")
    stub_request(:get, "http://upstream.test/report")
      .with(headers: { "Authorization" => "Bearer new" })
      .to_return(status: 200, body: "hello world")
    chunks = []

    client.stream(:get, "report") { |chunk| chunks << chunk }

    expect(chunks.join).to eq("hello world")
    expect(refreshing.refreshes).to eq(1)
  end

  it "raises auth.expired after a second streamed 401" do
    refreshing = Class.new do
      attr_reader :refreshes

      def initialize
        @refreshes = 0
      end

      def token = "old"
      def service? = false

      def refresh!
        @refreshes += 1
      end
    end.new
    client = Rafelo::Core::UpstreamClient.new(name: :download, config: config, token_provider: refreshing)
    stub_request(:get, "http://upstream.test/report").to_return(status: 401, body: "{}")
    chunks = []

    expect do
      client.stream(:get, "report") { |chunk| chunks << chunk }
    end.to raise_error(Rafelo::Core::ApplicationError) { |error| expect(error.code).to eq("auth.expired") }

    expect(chunks).to be_empty
    expect(refreshing.refreshes).to eq(1)
  end

  it "rejects an error status before yielding a byte" do
    stub_request(:get, "http://upstream.test/report").to_return(status: 500, body: "boom")
    chunks = []

    expect do
      client.stream(:get, "report") { |chunk| chunks << chunk }
    end.to raise_error(Rafelo::Core::ApplicationError)

    expect(chunks).to be_empty
  end

  def stalled_config(threshold:, cool_off: 30)
    Rafelo::Core::UpstreamConfig.new(
      base_url: "http://upstream.test",
      open_timeout: 1, read_timeout: 2, write_timeout: 1,
      max_concurrent_calls: 2, max_response_bytes: 100,
      retry_budget: 0, idempotency_keys: false,
      service_token_gateways: [], breaker: { failure_threshold: threshold, cool_off: cool_off }
    )
  end

  it "does not record an outcome when the viewer stalls inside the call" do
    config = stalled_config(threshold: 1)
    client = Rafelo::Core::UpstreamClient.new(name: :stalled_download, config: config, token_provider: token)
    stub_request(:get, "http://upstream.test/report").to_return(status: 200, body: "hello world")
    allow(Rafelo::Core::Metrics).to receive(:record_upstream_error)

    result = catch(:rafelo_download_stalled) do
      client.stream(:get, "report") { throw :rafelo_download_stalled, :stalled }
      :finished
    end

    expect(result).to eq(:stalled)
    chunks = []
    client.stream(:get, "report") { |chunk| chunks << chunk }

    expect(chunks.join).to eq("hello world")
    expect(Rafelo::Core::Metrics).not_to have_received(:record_upstream_error)
  end

  it "keeps a stall from resetting the upstream failure streak" do
    config = stalled_config(threshold: 2)
    client = Rafelo::Core::UpstreamClient.new(name: :stalled_streak, config: config, token_provider: token)
    stub_request(:get, "http://upstream.test/report").to_return(status: 500, body: "boom")
    stub_request(:get, "http://upstream.test/stall").to_return(status: 200, body: "hello")

    expect { client.stream(:get, "report") { } }.to raise_error(Rafelo::Core::ApplicationError)
    expect do
      catch(:rafelo_download_stalled) do
        client.stream(:get, "stall") { throw :rafelo_download_stalled }
      end
    end.not_to raise_error
    expect { client.stream(:get, "report") { } }.to raise_error(Rafelo::Core::ApplicationError)

    expect do
      client.stream(:get, "report") { }
    end.to raise_error(Rafelo::Core::ApplicationError) { |error| expect(error.code).to eq("upstream.circuit_open") }
  end

  it "leaves a half-open circuit open when the viewer stalls" do
    config = stalled_config(threshold: 1, cool_off: 1)
    client = Rafelo::Core::UpstreamClient.new(name: :stalled_probe, config: config, token_provider: token)
    stub_request(:get, "http://upstream.test/report").to_return(status: 500, body: "boom")
    stub_request(:get, "http://upstream.test/stall").to_return(status: 200, body: "hello")
    breaker = client.instance_variable_get(:@breaker)

    expect { client.stream(:get, "report") { } }.to raise_error(Rafelo::Core::ApplicationError)
    expect(breaker.color).to eq(:red)

    sleep 1.1
    expect(breaker.color).to eq(:yellow)

    catch(:rafelo_download_stalled) do
      client.stream(:get, "stall") { throw :rafelo_download_stalled }
    end

    expect(breaker.color).to eq(:yellow)
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
