require "rails_helper"

RSpec.describe Rafelo::Core::Flags do
  it "loads flags once and answers a missing flag as off" do
    flags = described_class.load("billing" => true, "search" => false)

    expect(flags[:billing]).to be(true)
    expect(flags[:search]).to be(false)
    expect(flags[:missing]).to be_nil
  end

  it "reads the configured flags" do
    expect(described_class.current).to include(billing: false)
    expect(described_class.enabled?(:billing)).to be(false)
  end
end
