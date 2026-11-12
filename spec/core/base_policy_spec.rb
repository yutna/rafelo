require "rails_helper"

RSpec.describe Rafelo::Core::BasePolicy do
  it "denies by default" do
    policy = described_class.new(Struct.new(:permissions).new(Rafelo::Core::PermissionSet.new([ "*" ])))

    expect(policy.index?).to be(false)
    expect(policy.create?).to be(false)
  end
end
