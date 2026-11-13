require "rails_helper"

RSpec.describe Rafelo::Core::DateFormatter do
  it "shows a Buddhist Era year in Thai and keeps the Gregorian year in English" do
    date = Date.new(2026, 11, 11)

    expect(described_class.format(date, locale: :th)).to eq("11 พฤศจิกายน 2569")
    expect(described_class.format(date, locale: :en)).to eq("11 November 2026")
  end
end
