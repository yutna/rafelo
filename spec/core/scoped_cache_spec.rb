require "rails_helper"

RSpec.describe Rafelo::Core::ScopedCache do
  before { Rails.cache.clear }

  it "caches a public value under the release, module and locale" do
    calls = 0
    fetch = -> { described_class.fetch(scope: :public, owner: :core, key: "currencies", ttl: 1.minute, locale: "en") { calls += 1; [ "THB" ] } }

    expect(fetch.call).to eq([ "THB" ])
    expect(fetch.call).to eq([ "THB" ])
    expect(calls).to eq(1)
  end

  it "separates viewer entries by viewer id and grant digest" do
    viewer = Struct.new(:id).new(1)
    key = ->(grants) { described_class.fetch(scope: :viewer, owner: :core, key: "invoices", ttl: 1.minute, viewer: viewer, grants: grants, locale: "en") { grants.join(",") } }

    expect(key.call([ "a" ])).to eq("a")
    expect(key.call([ "b" ])).to eq("b")
  end

  it "rejects an unknown scope and a viewer cache without a viewer" do
    expect { described_class.fetch(scope: :shared, owner: :core, key: "x", ttl: 1.minute) { 1 } }.to raise_error(ArgumentError)
    expect { described_class.fetch(scope: :viewer, owner: :core, key: "x", ttl: 1.minute) { 1 } }.to raise_error(ArgumentError)
  end
end
