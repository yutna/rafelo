require "rails_helper"

RSpec.describe Rafelo::Core::AssetVersion do
  after { described_class.reset! }

  it "computes the digest once under concurrent threads" do
    calls = 0
    allow(ViteRuby).to receive(:digest) do
      sleep 0.05
      calls += 1
      "digest-threaded"
    end
    described_class.reset!

    values = 2.times.map { Thread.new { described_class.call } }.map(&:value)

    expect(values).to eq([ "digest-threaded", "digest-threaded" ])
    expect(calls).to eq(1)
  end

  it "memoizes the digest" do
    allow(ViteRuby).to receive(:digest).and_return("digest-1")
    described_class.reset!

    expect(described_class.call).to eq("digest-1")
    expect(described_class.call).to eq("digest-1")
    expect(ViteRuby).to have_received(:digest).once
  end
end
