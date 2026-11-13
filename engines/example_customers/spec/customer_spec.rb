require_relative "rails_helper"

RSpec.describe Rafelo::ExampleCustomers::Customer do
  it "is an immutable public value object" do
    customer = described_class.new(id: "7", name: "Ada", tier: "gold")

    expect(customer.id).to eq("7")
    expect(customer.frozen?).to be(true)
  end
end

RSpec.describe Rafelo::ExampleCustomers::CustomersGateway do
  it "maps an upstream customer into the public value object" do
    stub_request(:get, "http://localhost:4000/customers/7")
      .to_return(status: 200, body: { data: { id: 7, name: "Ada", tier: "gold" } }.to_json,
                 headers: { "Content-Type" => "application/json" })
    gateway = described_class.new(
      token_provider: Struct.new(:token, :service?).new("access", false),
      budget: Rafelo::Core::CallBudget.new(api: 1),
      request_id: "request-1",
      trace_id: "trace-1"
    )

    customer = gateway.find("7")

    expect(customer).to eq(Rafelo::ExampleCustomers::Customer.new(id: "7", name: "Ada", tier: "gold"))
  end
end
