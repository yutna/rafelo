require "rails_helper"

RSpec.describe Rafelo::Core::Executor do
  it "runs work off the caller thread and shuts down" do
    executor = described_class.new(2)
    queue = Queue.new
    executor.post { queue << "done" }

    expect(queue.pop).to eq("done")
  ensure
    executor&.shutdown
  end
end
