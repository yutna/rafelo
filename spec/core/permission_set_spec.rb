require "rails_helper"

RSpec.describe Rafelo::Core::PermissionSet do
  it "matches wildcard, prefix, resource and exact grants" do
    permissions = described_class.new([
      "*",
      "billing:*",
      "billing:invoice:*",
      "billing:invoice:read"
    ])

    expect(permissions.allows?("billing:invoice:read")).to be(true)
    expect(permissions.allows?("billing:invoice:create")).to be(true)
    expect(permissions.allows?("billing:payment:read")).to be(true)
    expect(permissions.allows?("other:invoice:read")).to be(true)
  end

  it "drops every malformed grant shape" do
    malformed = [ "billing", "billing:", "billing:invoice", "*:*", "billing:*:read", "Billing:Invoice:Read" ]
    permissions = described_class.new(malformed)

    malformed.each do |grant|
      expect(permissions.allows?("billing:invoice:read")).to be(false), "#{grant.inspect} matched"
    end
  end

  it "rejects malformed required keys" do
    permissions = described_class.new([ "billing:invoice:read" ])

    expect { permissions.allows?("billing:invoice") }.to raise_error(ArgumentError)
    expect { permissions.allows?("billing:*:read") }.to raise_error(ArgumentError)
  end

  it "answers reads_any? only for read grants under the given prefixes" do
    permissions = described_class.new([
      "billing:invoice:read",
      "catalog:*",
      "other:invoice:create"
    ])

    expect(permissions.reads_any?([ "billing" ])).to be(true)
    expect(permissions.reads_any?([ "catalog" ])).to be(true)
    expect(permissions.reads_any?([ "other" ])).to be(false)
    expect(permissions.reads_any?([ "missing" ])).to be(false)
  end
end
