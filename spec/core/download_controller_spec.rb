require "rails_helper"

RSpec.describe Rafelo::Core::DownloadController do
  let(:permit) { Object.new }
  let(:deadline) { Rafelo::Core::RequestDeadline.new(0.1) }

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
    controller = build_controller(deadline)
    released = Queue.new
    stream = Class.new do
      def write(_chunk)
        sleep 0.4
      end
    end.new
    allow(controller).to receive(:send_stream).and_yield(stream)
    source = lambda do |&block|
      20.times { |index| block.call("chunk-#{index}") }
    ensure
      released << true
    end

    expect do
      controller.send(:send_download, filename: "report.txt", source: source)
    end.to raise_error(Rafelo::Core::ApplicationError) { |error| expect(error.code).to eq("upstream.timeout") }

    expect(released).not_to be_empty
  end

  it "fails the consumer as upstream.timeout when no chunk arrives before the deadline" do
    controller = build_controller(deadline)
    allow(controller).to receive(:send_stream)
    source = ->(&_block) { sleep 0.4 }

    expect do
      controller.send(:send_download, filename: "report.txt", source: source)
    end.to raise_error(Rafelo::Core::ApplicationError) { |error| expect(error.code).to eq("upstream.timeout") }

    expect(controller).not_to have_received(:send_stream)
  end
end
