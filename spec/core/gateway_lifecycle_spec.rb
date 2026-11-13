require "rails_helper"

RSpec.describe "Gateway lifecycle" do
  let(:token) { Struct.new(:token, :service?).new("secret", false) }
  let(:budget) { Rafelo::Core::CallBudget.new(api: 3) }
  let(:gateway) do
    ExampleInvoicesGateway.new(token_provider: token, budget: budget, request_id: "r", trace_id: "t")
  end

  it "holds one client for the gateway lifetime" do
    expect(gateway.client).to be(gateway.client)
  end

  it "maps an upstream payload into a value object" do
    stub_upstream(:get, "/invoices/inv_1", fixture: "invoices/show.json", base_url: "http://localhost:4000")

    invoice = gateway.find("inv_1")

    expect(invoice).to be_a(ExampleInvoice)
    expect(invoice.id).to eq("inv_1")
    expect(invoice.number).to eq("INV-1")
  end
end
