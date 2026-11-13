require "rails_helper"

RSpec.describe Rafelo::Core::ReturnTo do
  def target(value, locale: :en)
    described_class.new(value, locale:).to_s
  end

  it "keeps a locale-scoped app path" do
    expect(target("/en/invoices/7?tab=lines")).to eq("/en/invoices/7?tab=lines")
    expect(target("/th/items")).to eq("/th/items")
    expect(target("/en")).to eq("/en")
  end

  it "refuses every hostile input" do
    [
      "//host",
      "https://host",
      "en/x",
      "/fr/x",
      "/en//x",
      "/en\\x",
      "/en/../x",
      "/en/%2e%2e/x",
      "/en/.%2E/x",
      "/en/%01x",
      "/en/%0Ax"
    ].each do |value|
      expect(target(value)).to eq("/en"), "#{value.inspect} must fall back"
    end
  end

  it "reads the value once, so a double-encoded dot stays literal" do
    expect(target("/en/%252e%252e/x")).to eq("/en/%252e%252e/x")
  end

  it "accepts another configured locale and falls back when blank" do
    expect(target("/th/x", locale: :en)).to eq("/th/x")
    expect(target(nil)).to eq("/en")
  end
end
