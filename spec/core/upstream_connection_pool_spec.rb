# frozen_string_literal: true

require "rails_helper"

RSpec.describe Rafelo::Core::UpstreamConnectionPool do
  def config(max_concurrent_calls: 8, base_url: "http://pool.test")
    Rafelo::Core::UpstreamConfig.new(
      base_url: base_url,
      open_timeout: 1,
      read_timeout: 2,
      write_timeout: 2,
      max_concurrent_calls: max_concurrent_calls,
      max_response_bytes: 1024,
      retry_budget: 0.1,
      idempotency_keys: false,
      service_token_gateways: [],
      breaker: { failure_threshold: 5, cool_off: 1 }
    )
  end

  it "keeps one pool per named upstream and configuration" do
    first = described_class.for(:pool_api, config)

    expect(described_class.for(:pool_api, config)).to be(first)
    expect(described_class.for(:pool_other, config)).not_to be(first)
    expect(described_class.for(:pool_api, config(base_url: "http://other.test"))).not_to be(first)
  end

  it "sizes the pool from the Puma thread count and the bulkhead" do
    threads = Rails.application.config.x.puma_threads

    expect(described_class.for(:pool_large, config(max_concurrent_calls: 8)).size)
      .to eq([ threads, 8 ].min)
    expect(described_class.for(:pool_small, config(max_concurrent_calls: 1)).size).to eq(1)
  end

  it "reuses a borrowed connection after the call returns" do
    pool = described_class.new(size: 1) { Object.new }
    deadline = Rafelo::Core::RequestDeadline.new(1)

    first = pool.with(deadline: deadline) { |connection| connection }
    second = pool.with(deadline: deadline) { |connection| connection }

    expect(first).to be(second)
  end

  it "times out when no connection is free before the deadline" do
    pool = described_class.new(size: 1) { :connection }

    pool.with(deadline: Rafelo::Core::RequestDeadline.new(1)) do
      expect { pool.with(deadline: Rafelo::Core::RequestDeadline.new(0.02)) { :never } }
        .to raise_error(Rafelo::Core::ApplicationError) { |error| expect(error.code).to eq("upstream.timeout") }
    end
  end
end
