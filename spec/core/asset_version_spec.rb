require "rails_helper"

RSpec.describe Rafelo::Core::AssetVersion do
  after { described_class.reset! }

  it "memoizes the digest" do
    allow(ViteRuby).to receive(:digest).and_return("digest-1")
    described_class.reset!

    expect(described_class.call).to eq("digest-1")
    expect(described_class.call).to eq("digest-1")
    expect(ViteRuby).to have_received(:digest).once
  end
end
