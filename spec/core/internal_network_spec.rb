# frozen_string_literal: true

require "rails_helper"

RSpec.describe Rafelo::Core::InternalNetwork do
  it "accepts loopback, private, and link-local addresses" do
    %w[127.0.0.1 10.1.2.3 172.16.4.5 192.168.1.1 169.254.10.1 ::1 fc00::1 fe80::1 ::ffff:10.0.0.7].each do |address|
      expect(described_class.include?(address)).to be(true), address
    end
  end

  it "refuses public addresses and values that are not addresses" do
    %w[203.0.113.9 8.8.8.8 2001:db8::1 example.test ""].each do |address|
      expect(described_class.include?(address)).to be(false), address
    end
  end
end
