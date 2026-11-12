require "rails_helper"

RSpec.describe Rafelo::Core::ListQuery do
  def params(hash)
    ActionController::Parameters.new(hash)
  end

  it "clamps page and per_page and keeps an allowed sort" do
    query = described_class.from(params(page: "2", per_page: "1000", sort: "issued_on"), sort: %w[issued_on total])

    expect(query.page).to eq(2)
    expect(query.per_page).to eq(100)
    expect(query.sort).to eq("issued_on")
  end

  it "turns non-scalar and out-of-range paging into defaults" do
    query = described_class.from(params(page: "0", per_page: "-2"), sort: [])

    expect(query.page).to eq(1)
    expect(query.per_page).to eq(25)
  end

  it "drops nested, oversized and undeclared filters" do
    query = described_class.from(
      params(status: { "$ne" => "paid" }, q: "x" * 201, tags: [ "a", "b" ]),
      sort: [],
      filters: { status: %w[paid], q: nil, tags: { multiple: 1 } }
    )

    expect(query.filters).to eq({})
  end

  it "keeps a scalar filter and a bounded cursor" do
    query = described_class.from(
      params(status: "paid", cursor: "opaque", direction: "desc"),
      sort: [],
      filters: { status: %w[paid draft] }
    )

    expect(query.filters).to eq("status" => "paid")
    expect(query.cursor).to eq("opaque")
    expect(query.direction).to eq("desc")
  end

  it "drops a nested array on a single-valued filter" do
    query = described_class.from(params(status: [ "paid" ]), sort: [], filters: { status: %w[paid] })

    expect(query.filters).to eq({})
  end
end
