require "rails_helper"
require "timeout"

RSpec.describe "Bounded executor concurrency", :concurrency do
  it "runs no more than its size and starts the queued unit after a slot frees" do
    executor = Rafelo::Core::Executor.new(2)
    started = Queue.new
    release = Queue.new
    3.times do |index|
      executor.post do
        started << index
        release.pop
      end
    end

    first = []
    Timeout.timeout(5) { 2.times { first << started.pop } }
    expect(first.sort).to eq([ 0, 1 ])
    expect(started).to be_empty

    2.times { release << true }
    expect(Timeout.timeout(5) { started.pop }).to eq(2)

    release << true
    executor.shutdown
  ensure
    executor&.shutdown
  end
end
