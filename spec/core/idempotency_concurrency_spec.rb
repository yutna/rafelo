require "rails_helper"
require "timeout"

RSpec.describe "Idempotency claim concurrency", :concurrency, truncate: %w[core_idempotency_keys core_sessions] do
  self.use_transactional_tests = false

  it "ignores the late outcome of a taken-over attempt" do
    viewer = Struct.new(:id, :name).new(7, "Ada")
    session, = Rafelo::Core::Session.start(
      viewer: viewer, access_token: "a", refresh_token: "r", access_expires_at: 5.minutes.from_now
    )
    token = Rafelo::Core::FormToken.issue(session_id: session.id)
    controller = double("controller", response: double(location: "/en/done"))
    allow(controller).to receive(:redirect_after_write)
    allow(controller).to receive(:redirect_to)
    entered = Queue.new
    release = Queue.new

    first = Thread.new do
      Rafelo::Core::Current.set(session: session) do
        Rafelo::Core::IdempotencyClaim.call(controller, token: token, payload: { name: "ada" }, back: "/en/form") do
          entered << true
          release.pop
          :ok
        end
      end
    end
    Timeout.timeout(5) { entered.pop }
    Rafelo::Core::IdempotencyKey.update_all(claimed_at: 10.minutes.ago)

    second = Thread.new do
      Rafelo::Core::Current.set(session: session) do
        Rafelo::Core::IdempotencyClaim.call(controller, token: token, payload: { name: "ada" }, back: "/en/form") { :ok }
      end
    end
    expect(second.value).to eq(:performed)

    release << true
    expect(first.value).to eq(:performed)

    row = Rafelo::Core::IdempotencyKey.first
    expect(row.status).to eq("succeeded")
    expect(row.attempt).to eq(2)
  ensure
    first&.kill
    second&.kill
  end
  it "lets only one of two first claims perform the write" do
    viewer = Struct.new(:id, :name).new(7, "Ada")
    session, = Rafelo::Core::Session.start(
      viewer: viewer, access_token: "a", refresh_token: "r", access_expires_at: 5.minutes.from_now
    )
    token = Rafelo::Core::FormToken.issue(session_id: session.id)
    controller = double("controller", response: double(location: "/en/done"))
    allow(controller).to receive(:redirect_after_write)
    allow(controller).to receive(:redirect_to)
    entered = Queue.new
    release = Queue.new
    results = Queue.new

    first = Thread.new do
      Rafelo::Core::Current.set(session: session) do
        results << Rafelo::Core::IdempotencyClaim.call(controller, token: token, payload: { name: "ada" }, back: "/en/form") do
          entered << true
          release.pop
          :ok
        end
      end
    end
    Timeout.timeout(5) { entered.pop }

    second = Thread.new do
      Rafelo::Core::Current.set(session: session) do
        results << Rafelo::Core::IdempotencyClaim.call(controller, token: token, payload: { name: "ada" }, back: "/en/form") { :ok }
      end
    end
    second.value
    release << true
    first.value

    outcomes = 2.times.map { results.pop }
    expect(outcomes.count(:performed)).to eq(1)
    expect(Rafelo::Core::IdempotencyKey.count).to eq(1)
  ensure
    first&.kill
    second&.kill
  end
  it "loses the unique insert without performing a second write" do
    viewer = Struct.new(:id, :name).new(7, "Ada")
    session, = Rafelo::Core::Session.start(
      viewer: viewer, access_token: "a", refresh_token: "r", access_expires_at: 5.minutes.from_now
    )
    token = Rafelo::Core::FormToken.issue(session_id: session.id)
    controller = double("controller", response: double(location: "/en/done"))
    allow(controller).to receive(:redirect_after_write)
    allow(controller).to receive(:redirect_to)
    start = Concurrent::CyclicBarrier.new(2)
    results = Queue.new
    threads = 2.times.map do
      Thread.new do
        Rafelo::Core::Current.set(session: session) do
          start.wait
          results << Rafelo::Core::IdempotencyClaim.call(
            controller, token: token, payload: { name: "ada" }, back: "/en/form"
          ) { :ok }
        end
      end
    end
    threads.each(&:value)
    outcomes = 2.times.map { results.pop }

    expect(outcomes.count(:performed)).to eq(1)
    expect(Rafelo::Core::IdempotencyKey.count).to eq(1)
  ensure
    threads&.each(&:kill)
  end
end
