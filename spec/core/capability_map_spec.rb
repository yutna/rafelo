require "rails_helper"

RSpec.describe Rafelo::Core::CapabilityMap do
  policy_class = Class.new(Rafelo::Core::BasePolicy) do
    def create? = true
    def export? = false
  end

  it "mirrors the named policy methods and strips the prefix" do
    capabilities = described_class.new(
      policy: policy_class.new(nil),
      entries: [
        Rafelo::Core::CapabilityMap::Entry.new(key: "billing:invoice:create", policy_method: :create?, flag: nil),
        Rafelo::Core::CapabilityMap::Entry.new(key: "billing:invoice:export", policy_method: :export?, flag: nil)
      ]
    )

    expect(capabilities.to_h).to eq(
      "invoice.create" => { allowed: true, reason: nil },
      "invoice.export" => { allowed: false, reason: "forbidden" }
    )
  end

  it "reports forbidden when the flag is on but the policy denies" do
    capabilities = described_class.new(
      policy: policy_class.new(nil),
      entries: [
        Rafelo::Core::CapabilityMap::Entry.new(key: "billing:invoice:export", policy_method: :export?, flag: :billing)
      ],
      flags: { billing: true }
    )

    expect(capabilities.to_h).to eq("invoice.export" => { allowed: false, reason: "forbidden" })
  end

  it "reports a disabled flag without calling the policy" do
    capabilities = described_class.new(
      policy: policy_class.new(nil),
      entries: [
        Rafelo::Core::CapabilityMap::Entry.new(key: "billing:invoice:create", policy_method: :create?, flag: :billing)
      ],
      flags: { billing: false }
    )

    expect(capabilities.to_h).to eq("invoice.create" => { allowed: false, reason: "disabled" })
  end
end
