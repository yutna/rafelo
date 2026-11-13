require "rails_helper"

RSpec.describe Rafelo::Core::BaseJob do
  let(:job_class) do
    Class.new(described_class) do
      cattr_accessor :seen

      def perform(value)
        self.class.seen = [ value, Rafelo::Core::Current.request_id, Rafelo::Core::Current.trace_id ]
      end
    end
  end

  before do
    stub_const("RafeloJobProbe", job_class)
    ActiveJob::Base.queue_adapter.enqueued_jobs.clear
  end

  after do
    Rafelo::Core::Current.reset
    ActiveJob::Base.queue_adapter.enqueued_jobs.clear
  end

  it "carries request and trace ids outside the declared arguments" do
    Rafelo::Core::Current.request_id = "request-1"
    Rafelo::Core::Current.trace_id = "trace-1"

    data = RafeloJobProbe.new("41").serialize

    expect(data["arguments"]).to eq([ "41" ])
    expect(data["rafelo_request_id"]).to eq("request-1")
    expect(data["rafelo_trace_id"]).to eq("trace-1")
  end

  it "restores the ids and sets them around perform" do
    Rafelo::Core::Current.request_id = "request-1"
    Rafelo::Core::Current.trace_id = "trace-1"
    data = RafeloJobProbe.new("41").serialize
    Rafelo::Core::Current.reset

    RafeloJobProbe.deserialize(data).perform_now

    expect(RafeloJobProbe.seen).to eq([ "41", "request-1", "trace-1" ])
    expect(Rafelo::Core::Current.request_id).to be_nil
  end

  it "starts a fresh trace outside a request" do
    data = RafeloJobProbe.new("41").serialize

    expect(data["rafelo_request_id"]).to be_nil
    expect(data["rafelo_trace_id"]).to match(/\A\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\z/)
  end

  it "does not log arguments" do
    expect(described_class.log_arguments).to be(false)
    expect(RafeloJobProbe.log_arguments).to be(false)
  end

  it "enqueues only after the surrounding transaction commits" do
    ActiveRecord::Base.transaction do
      RafeloJobProbe.perform_later("41")
      expect(ActiveJob::Base.queue_adapter.enqueued_jobs).to be_empty
    end

    expect(ActiveJob::Base.queue_adapter.enqueued_jobs.length).to eq(1)
  end

  it "makes every application and engine job inherit the base" do
    Rails.application.eager_load!

    roots = [ Rails.root.join("app/jobs") ] + Rails.root.glob("engines/*/app/jobs")
    files = roots.flat_map { |root| root.glob("**/*.rb") }.reject { |path| path.to_s.include?("/spec/") }

    files.each do |file|
      relative = file.to_s.split("/app/jobs/").last.sub(/\.rb\z/, "")
      klass = relative.camelize.constantize
      next if klass == described_class

      expect(klass.ancestors).to include(described_class), "#{klass} must inherit Rafelo::Core::BaseJob"
    end
  end
end
