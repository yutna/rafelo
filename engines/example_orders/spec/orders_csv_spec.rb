require_relative "rails_helper"

RSpec.describe Rafelo::ExampleOrders::OrdersCsv do
  it "quotes delimiters and neutralizes formula injection" do
    order = Rafelo::ExampleOrders::Order.new(
      id: "1", number: "ORD-1", customer_id: "7", customer_name: "=SUM(A1), Ada",
      customer_tier: "gold", status: "open", total_minor: 100, currency: "THB",
      issued_on: "2026-01-01", version: 1
    )

    csv = described_class.render([ order ])

    expect(csv.lines.first).to eq("number,customer,status,total_minor\n")
    expect(csv).to include("\"'=SUM(A1), Ada\"")
  end
end
