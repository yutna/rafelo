require_relative "rails_helper"

RSpec.describe Rafelo::ExampleOrders::OrderExportJob do
  it "exports every page with CSV-safe fields" do
    viewer = Struct.new(:id, :name).new(7, "Ada")
    session, = Rafelo::Core::Session.start(
      viewer: viewer, access_token: "access", refresh_token: "refresh",
      access_expires_at: 5.minutes.from_now
    )
    export = Rafelo::Core::Export.build_for(viewer: viewer, filename: "orders.csv")
    page_one = {
      items: [ {
        id: "1", number: "ORD-1", customer: { id: "7", name: "=SUM(A1)", tier: "gold" },
        status: "open", total_minor: 100, currency: "THB", issued_on: "2026-01-01", version: 1
      } ],
      pagination: { total: 2 }
    }
    page_two = {
      items: [ {
        id: "2", number: "ORD-2", customer: { id: "8", name: "Grace", tier: "silver" },
        status: "paid", total_minor: 200, currency: "THB", issued_on: "2026-01-02", version: 1
      } ],
      pagination: { total: 2 }
    }
    stub_request(:get, "http://localhost:4000/orders")
      .with(query: hash_including("page" => "1"))
      .to_return(status: 200, body: page_one.to_json, headers: { "Content-Type" => "application/json" })
    stub_request(:get, "http://localhost:4000/orders")
      .with(query: hash_including("page" => "2"))
      .to_return(status: 200, body: page_two.to_json, headers: { "Content-Type" => "application/json" })

    described_class.perform_now(session.id, export.id)

    csv = export.reload.file.download
    expect(csv).to include("ORD-1")
    expect(csv).to include("'=SUM(A1)")
    expect(csv).to include("ORD-2")
  end
end
