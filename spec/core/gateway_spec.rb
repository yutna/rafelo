require "rails_helper"

RSpec.describe Rafelo::Core::Gateway do
  let(:token) { Struct.new(:token).new("secret") }
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

  it "counts calls against the per-request budget" do
    budget.consume!(:api)
    budget.consume!(:api)

    expect { budget.consume!(:api) }.to raise_error(Rafelo::Core::ApplicationError) { |error| expect(error.code).to eq("request.throttled") }
  end
end
