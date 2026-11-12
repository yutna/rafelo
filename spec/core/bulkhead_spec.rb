require "rails_helper"

RSpec.describe Rafelo::Core::Bulkhead do
  it "admits up to the limit and fails a call that cannot get a slot" do
    bulkhead = described_class.new(1, wait: 0.01)
    started = Queue.new
    release = Queue.new
    thread = Thread.new do
      bulkhead.call do
        started << true
        release.pop
      end
    end
    started.pop

    expect { bulkhead.call { :never } }.to raise_error(Rafelo::Core::ApplicationError, /unavailable/)
    expect { bulkhead.call { :never } }.to raise_error(Rafelo::Core::ApplicationError, /unavailable/)
  ensure
    release << true
    thread&.join
  end
end
