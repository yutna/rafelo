require "rails_helper"

RSpec.describe Rafelo::Core::RequestDeadline do
  it "reports the remaining monotonic time and expires" do
    deadline = described_class.new(0.05)
    expect(deadline).not_to be_expired
    sleep 0.06
    expect(deadline).to be_expired
    expect(deadline.remaining).to eq(0.0)
  end
end
