require_relative "rails_helper"

RSpec.describe Rafelo::ExampleOrders::OrderForm do
  it "accepts a known status and rejects a missing customer" do
    expect(described_class.new(customer_name: "Ada", status: "open")).to be_valid
    expect(described_class.new(customer_name: "", status: "open")).not_to be_valid
    expect(described_class.new(customer_name: "Ada", status: "unknown")).not_to be_valid
  end
end

RSpec.describe Rafelo::ExampleOrders::OrderPolicy do
  let(:viewer) { Struct.new(:id, :name).new(7, "Ada") }

  it "allows export only with the export grant" do
    policy = described_class.new(viewer, permissions: Rafelo::Core::PermissionSet.new([ "example_orders:order:read" ]))
    expect(policy.index?).to be(true)
    expect(policy.export?).to be(false)

    exported = described_class.new(viewer, permissions: Rafelo::Core::PermissionSet.new([ "example_orders:order:export" ]))
    expect(exported.export?).to be(true)
  end
end

RSpec.describe Rafelo::ExampleOrders::OrdersGateway do
  def gateway
    described_class.new(
      token_provider: Struct.new(:token, :service?).new("access", false),
      budget: Rafelo::Core::CallBudget.new(api: 3),
      request_id: "request-1",
      trace_id: "trace-1"
    )
  end

  it "maps malformed JSON to the unexpected catalog error" do
    stub_request(:get, "http://localhost:4000/orders").with(query: hash_including({})).to_return(status: 200, body: "not-json")

    expect { gateway.list(Rafelo::Core::ListQuery.from({}, sort: %w[number])) }
      .to raise_error(Rafelo::Core::ApplicationError) { |error| expect(error.code).to eq("unexpected") }
  end
end
