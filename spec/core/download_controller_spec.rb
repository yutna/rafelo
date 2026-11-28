require "rails_helper"

RSpec.describe Rafelo::Core::DownloadController do
  # A deadline the example controls, so a stalled producer or consumer never
  # depends on a sleep racing a real clock (TS-01, TS-10).
  def fake_deadline(remaining = 1.0)
    Class.new do
      attr_accessor :remaining

      def initialize(remaining)
        @remaining = remaining
      end

      def expire!
        @remaining = 0.0
      end
    end.new(remaining)
  end

  let(:permit) { Object.new }

  def build_controller(deadline)
    controller = described_class.new
    allow(controller).to receive(:pundit_policy_authorized?).and_return(true)
    allow(controller).to receive(:request_deadline).and_return(deadline)
    allow(Rafelo::Core::DownloadLimiter).to receive(:acquire).and_return(permit)
    allow(Rafelo::Core::DownloadLimiter).to receive(:release)
    allow(Rafelo::Core::AuditRecorder).to receive(:record)
    allow(controller).to receive(:response).and_return(double(headers: {}))
    Rafelo::Core::Current.request_id = "download-controller-spec"
    controller
  end

  after { Rafelo::Core::Current.reset }

  it "stops the producer at the deadline and releases the source when the consumer stalls" do
    deadline = fake_deadline
    controller = build_controller(deadline)
    released = Queue.new
    stream = Class.new do
      def initialize(deadline)
        @deadline = deadline
      end

      def write(_chunk)
        @deadline.expire!
      end
    end.new(deadline)
    allow(controller).to receive(:send_stream).and_yield(stream)
    source = lambda do |&block|
      loop { block.call("chunk") }
    ensure
      released << true
    end

    expect do
      controller.send(:send_download, filename: "report.txt", source: source)
    end.to raise_error(Rafelo::Core::ApplicationError) { |error| expect(error.code).to eq("upstream.timeout") }

    expect(released.pop(timeout: 2)).to eq(true)
  end

  it "fails the consumer as upstream.timeout when no chunk arrives before the deadline" do
    controller = build_controller(fake_deadline(0.0))
    allow(controller).to receive(:send_stream)
    source = ->(&_block) { }

    expect do
      controller.send(:send_download, filename: "report.txt", source: source)
    end.to raise_error(Rafelo::Core::ApplicationError) { |error| expect(error.code).to eq("upstream.timeout") }

    expect(controller).not_to have_received(:send_stream)
  end

  it "ends a source with no chunks as a zero-byte success" do
    controller = build_controller(fake_deadline)
    stream = double("stream", write: nil)
    allow(controller).to receive(:send_stream).and_yield(stream)

    expect do
      controller.send(:send_download, filename: "empty.txt", source: ->(&_block) { })
    end.not_to raise_error

    expect(stream).not_to have_received(:write)
    expect(Rafelo::Core::AuditRecorder).to have_received(:record).with(
      hash_including(event: "download", outcome: "success", target: "empty.txt")
    )
  end

  it "hands an error over when the queue has room" do
    controller = build_controller(fake_deadline)
    queue = SizedQueue.new(1)
    error = RuntimeError.new("boom")

    controller.send(:deliver_error, queue, fake_deadline, error)

    expect(queue.pop).to eq([ :error, error ])
  end

  it "gives up on the handoff when the queue is full and the deadline passed" do
    controller = build_controller(fake_deadline)
    queue = SizedQueue.new(1)
    queue.push(:first)

    controller.send(:deliver_error, queue, fake_deadline(0.0), RuntimeError.new("boom"))

    expect(queue.size).to eq(1)
    expect(queue.pop).to eq(:first)
  end

  it "waits for room and then hands the error over" do
    controller = build_controller(fake_deadline)
    queue = SizedQueue.new(1)
    queue.push(:first)
    taken = Queue.new
    consumer = Thread.new do
      taken << queue.pop
      queue.pop
    end
    taken.pop(timeout: 2)
    error = RuntimeError.new("boom")

    controller.send(:deliver_error, queue, fake_deadline, error)

    expect(consumer.value).to eq([ :error, error ])
  end

  it "gives up when the queue stays full for the whole wait" do
    controller = build_controller(fake_deadline)
    queue = double("queue")
    allow(queue).to receive(:push).and_raise(ThreadError)

    result = controller.send(:deliver_error, queue, fake_deadline(1.0), RuntimeError.new("boom"))

    expect(result).to be_nil
    expect(queue).to have_received(:push).twice
  end

  it "hands a producer error over a queue the consumer has not drained yet" do
    controller = build_controller(fake_deadline)
    queue = SizedQueue.new(1)
    allow(SizedQueue).to receive(:new).with(8).and_return(queue)
    writes = []
    stream = Class.new do
      def initialize(writes)
        @writes = writes
      end

      def write(chunk)
        @writes << chunk
      end
    end.new(writes)
    allow(controller).to receive(:send_stream).and_yield(stream)
    error = RuntimeError.new("boom")
    source = lambda do |&block|
      block.call("first")
      raise error
    end

    expect do
      controller.send(:send_download, filename: "report.txt", source: source)
    end.to raise_error(error)

    expect(writes).to eq([ "first" ])
    expect(Rafelo::Core::AuditRecorder).to have_received(:record).with(
      hash_including(event: "download", outcome: "failure", target: "report.txt")
    )
  end
end
