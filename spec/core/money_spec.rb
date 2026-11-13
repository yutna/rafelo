require "rails_helper"

RSpec.describe Rafelo::Core::Money do
  it "uses the ISO 4217 exponent for wire money" do
    expect(described_class.wire(1234, "THB")).to eq(minor: 1234, currency: "THB", exponent: 2)
    expect(described_class.wire(1234, "JPY")).to eq(minor: 1234, currency: "JPY", exponent: 0)
    expect(described_class.wire(1234, "kwd")).to eq(minor: 1234, currency: "KWD", exponent: 3)
  end
end
