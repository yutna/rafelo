require "rails_helper"
require "socket"

RSpec.describe Rafelo::Core::ViewerJob do
  let(:viewer) { Struct.new(:id, :name).new(7, "Ada") }
  let(:job_class) do
    Class.new(described_class) do
      cattr_accessor :seen

      def perform(session_id)
        with_viewer_session(session_id) do
          self.class.seen = {
            viewer: Rafelo::Core::Current.viewer.id,
            token: Rafelo::Core::Current.token_provider.token,
            locale: I18n.locale
          }
          @second_token = Rafelo::Core::Current.token_provider.token
        end
      end
    end
  end

  def start_session(ttl: 12.hours, last_seen_at: Time.current)
    session, = Rafelo::Core::Session.start(
      viewer: viewer, access_token: "access", refresh_token: "refresh",
      access_expires_at: 5.minutes.from_now, ttl: ttl
    )
    session.update_column(:last_seen_at, last_seen_at)
    session
  end

  before { stub_const("ViewerJobProbe", job_class) }
  after { Rafelo::Core::Current.reset }

  it "runs with the viewer's session and enqueuing locale" do
    session = start_session
    data = I18n.with_locale(:th) { ViewerJobProbe.new(session.id).serialize }

    ViewerJobProbe.execute(data)

    expect(ViewerJobProbe.seen).to include(viewer: "7", token: "access", locale: :th)
  end

  it "does not stop for an idle-expired session that is still absolute-live" do
    session = start_session(last_seen_at: 31.minutes.ago)

    ViewerJobProbe.perform_now(session.id)

    expect(ViewerJobProbe.seen).to include(viewer: "7")
  end

  it "stops cleanly when the session is revoked" do
    session = start_session
    session.destroy

    expect { ViewerJobProbe.perform_now(session.id) }.not_to raise_error
    expect(ViewerJobProbe.seen).to be_nil
  end

  it "stops cleanly when the session is past its absolute lifetime" do
    session = start_session(ttl: -1.minute)

    expect { ViewerJobProbe.perform_now(session.id) }.not_to raise_error
  end

  it "re-reads the session before every upstream call" do
    session = start_session
    job = ViewerJobProbe.new(session.id)
    Rafelo::Core::Session.find(session.id).update_column(:access_token, "rotated")

    job.perform_now

    expect(ViewerJobProbe.seen[:token]).to eq("rotated")
  end

  it "fails a unit at its deadline instead of waiting forever" do
    budget = Rafelo::Core::CallBudget.new(
      api: 1,
      deadline: Process.clock_gettime(Process::CLOCK_MONOTONIC) - 1
    )

    expect { budget.consume!(:api) }.to raise_error(Rafelo::Core::ApplicationError) { |error| expect(error.code).to eq("upstream.timeout") }
  end

  it "fails a unit at the job deadline when the upstream is slow" do
    session = start_session
    previous = Rails.application.config.x.jobs.upstream_deadline_seconds
    Rails.application.config.x.jobs.upstream_deadline_seconds = 0.1
    WebMock.allow_net_connect!
    server = TCPServer.new("127.0.0.1", 0)
    port = server.addr[1]
    thread = Thread.new do
      socket = server.accept
      socket.readpartial(4096)
      socket.write("HTTP/1.1 200 OK\r\nContent-Length: 100\r\n\r\n")
      20.times do
        socket.write("x" * 5)
        sleep 0.02
      end
    ensure
      socket&.close
      server.close
    end
    slow_job = Class.new(described_class) do
      define_method(:perform) do |session_id|
        with_viewer_session(session_id) do
          client = Rafelo::Core::UpstreamClient.new(
            name: :api,
            config: Rails.application.config.x.upstreams.fetch(:api).with(base_url: "http://127.0.0.1:#{port}"),
            token_provider: Rafelo::Core::Current.token_provider,
            budget: Rafelo::Core::Current.call_budget,
            deadline: Rafelo::Core::Current.call_budget.deadline,
            request_id: Rafelo::Core::Current.request_id,
            trace_id: Rafelo::Core::Current.trace_id
          )
          client.get("slow")
        end
      end
    end
    stub_const("SlowViewerJobProbe", slow_job)

    expect { SlowViewerJobProbe.perform_now(session.id) }
      .to raise_error(Rafelo::Core::ApplicationError) { |error| expect(error.code).to eq("upstream.timeout") }
  ensure
    thread&.kill
    server&.close
    WebMock.disable_net_connect!
    Rails.application.config.x.jobs.upstream_deadline_seconds = previous
  end

  it "leaves no failed execution row when a stopped job is discarded" do
    session = start_session
    session.destroy

    expect { ViewerJobProbe.perform_now(session.id) }.not_to raise_error
    expect(SolidQueue::FailedExecution.count).to eq(0)
  end
end
