require "rails_helper"

RSpec.describe Rafelo::Core::ScopedCache do
  before { Rails.cache.clear }

  it "caches a public value under the release, module and locale" do
    calls = 0
    fetch = -> { described_class.fetch(scope: :public, module: :core, key: "currencies", ttl: 1.minute, locale: "en") { calls += 1; [ "THB" ] } }

    expect(fetch.call).to eq([ "THB" ])
    expect(fetch.call).to eq([ "THB" ])
    expect(calls).to eq(1)
  end

  it "changes the namespace when the release changes, even with the same assets" do
    allow(Rafelo::Core::Release).to receive(:call).and_return("0.41.0:digest")
    described_class.fetch(scope: :public, module: :core, key: "currencies", ttl: 1.minute) { "old" }

    allow(Rafelo::Core::Release).to receive(:call).and_return("0.42.0:digest")
    expect(described_class.fetch(scope: :public, module: :core, key: "currencies", ttl: 1.minute) { "new" }).to eq("new")
  end

  it "uses an explicit schema version instead of the release" do
    keys = []
    allow(Rails.cache).to receive(:fetch) do |key, **|
      keys << key
      "v1"
    end

    described_class.fetch(scope: :public, module: :core, key: "currencies", ttl: 1.minute, schema_version: "v1") { "v1" }

    expect(keys.first).to include("rafelo/v1/core")
    expect(keys.first).not_to include(Rafelo::Core::Release.call)
  end

  it "separates viewer entries by viewer id and grant digest" do
    viewer = Struct.new(:id).new(1)
    key = ->(grants) { described_class.fetch(scope: :viewer, module: :core, key: "invoices", ttl: 1.minute, viewer: viewer, grants: grants, locale: "en") { grants.join(",") } }

    expect(key.call([ "a" ])).to eq("a")
    expect(key.call([ "b" ])).to eq("b")
  end

  it "rejects viewer data on a public cache" do
    viewer = Struct.new(:id).new(1)

    expect { described_class.fetch(scope: :public, module: :core, key: "x", ttl: 1.minute, viewer: viewer) { 1 } }
      .to raise_error(ArgumentError, /viewer data/)
  end

  it "rejects an unknown scope and a viewer cache without a viewer" do
    expect { described_class.fetch(scope: :shared, module: :core, key: "x", ttl: 1.minute) { 1 } }.to raise_error(ArgumentError)
    expect { described_class.fetch(scope: :viewer, module: :core, key: "x", ttl: 1.minute) { 1 } }.to raise_error(ArgumentError)
  end

  it "rejects a caller from another engine" do
    allow(described_class).to receive(:caller_locations).and_return(
      [ double(path: "/app/engines/billing/app/models/cache.rb") ]
    )

    expect do
      described_class.fetch(scope: :public, module: :core, key: "x", ttl: 1.minute) { 1 }
    end.to raise_error(ArgumentError, /may not use the core cache/)
  end
end
