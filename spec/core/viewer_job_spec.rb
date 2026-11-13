require "rails_helper"

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
end
