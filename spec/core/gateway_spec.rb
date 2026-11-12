require "rails_helper"

RSpec.describe Rafelo::Core::Gateway do
  let(:token) { Struct.new(:token, :service?).new("secret", false) }
  let(:budget) { Rafelo::Core::CallBudget.new(api: 2) }

  it "declares a known upstream and token kind and builds the client" do
    gateway_class = Class.new(described_class) do
      upstream :api
      token :viewer
    end

    gateway = gateway_class.new(token_provider: token, budget: budget, request_id: "r", trace_id: "t")

    expect(gateway.client).to be_a(Rafelo::Core::UpstreamClient)
    expect(gateway_class.token).to eq(:viewer)
  end

  it "raises on an unknown upstream when the class loads" do
    expect do
      Class.new(described_class) { upstream :missing }
    end.to raise_error(ArgumentError, /unknown upstream/)
  end

  it "rejects a service token unless the gateway is allow-listed" do
    expect do
      Class.new(described_class) do
        upstream :api
        token :service
      end
    end.to raise_error(ArgumentError, /not allow-listed/)
  end

  it "requires a service-token provider for an allow-listed service gateway" do
    config = Rails.application.config.x.upstreams.fetch(:api)
    allow(Rails.application.config.x).to receive(:upstreams).and_return(
      api: config.with(service_token_gateways: [ "ServiceGateway" ])
    )
    service_gateway = Class.new(described_class) { upstream :api }
    Object.const_set(:ServiceGateway, service_gateway)
    service_gateway.token :service

    expect { service_gateway.new(token_provider: token, budget: budget, request_id: "r", trace_id: "t") }
      .to raise_error(ArgumentError, /service token provider/)
  ensure
    Object.send(:remove_const, :ServiceGateway) if Object.const_defined?(:ServiceGateway)
  end

  it "rejects a viewer gateway built with a service provider" do
    viewer_gateway = Class.new(described_class) { upstream :api }
    service_provider = Struct.new(:token, :service?).new("service", true)

    expect { viewer_gateway.new(token_provider: service_provider, budget: budget, request_id: "r", trace_id: "t") }
      .to raise_error(ArgumentError, /viewer token provider/)
  end

  it "counts calls against the per-request budget" do
    budget.consume!(:api)
    budget.consume!(:api)

    expect { budget.consume!(:api) }.to raise_error(Rafelo::Core::ApplicationError) { |error| expect(error.code).to eq("request.throttled") }
  end
end
