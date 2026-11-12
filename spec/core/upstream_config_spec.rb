require "rails_helper"

RSpec.describe Rafelo::Core::UpstreamConfig do
  let(:raw) do
    {
      "api" => {
        base_url: "http://example.test",
        open_timeout: 1,
        read_timeout: 2,
        write_timeout: 3,
        max_concurrent_calls: 4,
        max_response_bytes: 1_024,
        retry_budget: 0.1,
        idempotency_keys: false,
        breaker: { failure_threshold: 2, cool_off: 5 }
      }
    }
  end

  it "loads one frozen typed entry per upstream" do
    config = described_class.load_all(raw)

    expect(config).to be_frozen
    expect(config[:api].base_url).to eq("http://example.test")
    expect(config[:api].breaker).to eq(failure_threshold: 2, cool_off: 5)
  end

  it "raises on a missing or unknown key" do
    expect { described_class.load_all(raw.merge("api" => raw["api"].except(:base_url))) }
      .to raise_error(ArgumentError, /missing/)
    expect { described_class.load_all(raw.merge("api" => raw["api"].merge(extra: true))) }
      .to raise_error(ArgumentError, /unknown/)
  end
end
