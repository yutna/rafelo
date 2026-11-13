require "rails_helper"

RSpec.describe Rafelo::Core::FormToken do
  include ActiveSupport::Testing::TimeHelpers

  it "verifies only its session and only within the row retention" do
    token = described_class.issue(session_id: 7)

    expect(described_class.verify(token, session_id: 7)).to be_a(Hash)
    expect(described_class.verify(token, session_id: 8)).to be_nil
    expect(described_class.verify("#{token}x", session_id: 7)).to be_nil

    travel 14.hours do
      expect(described_class.verify(token, session_id: 7)).to be_nil
    end
  end
end
