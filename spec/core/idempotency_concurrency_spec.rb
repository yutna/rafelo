require "rails_helper"
require "timeout"

RSpec.describe "Idempotency claim concurrency", :concurrency, truncate: %w[core_idempotency_keys core_sessions] do
  def session
    viewer = Struct.new(:id, :name).new(7, "Ada")
    Rafelo::Core::Session.start(
      viewer: viewer, access_token: "a", refresh_token: "r", access_expires_at: 5.minutes.from_now
    ).first
  end

  def controller_for(location)
    double("controller", response: double(location: location)).tap do |controller|
      allow(controller).to receive(:redirect_after_write)
      allow(controller).to receive(:redirect_to)
    end
  end

  it "ignores the late outcome of a taken-over attempt" do
    current_session = session
    token = Rafelo::Core::FormToken.issue(session_id: current_session.id)
    first_controller = controller_for("/en/first")
    second_controller = controller_for("/en/second")
    entered = latch
    release = latch

    first = Thread.new do
      Rafelo::Core::Current.set(session: current_session) do
        Rafelo::Core::IdempotencyClaim.call(first_controller, token: token, payload: { name: "ada" }, back: "/en/form") do
          entered.count_down
          release.wait(5)
          :ok
        end
      end
    end
    Timeout.timeout(5) { entered.wait }
    Rafelo::Core::IdempotencyKey.update_all(claimed_at: 10.minutes.ago)

    second = Thread.new do
      Rafelo::Core::Current.set(session: current_session) do
        Rafelo::Core::IdempotencyClaim.call(second_controller, token: token, payload: { name: "ada" }, back: "/en/form") { :ok }
      end
    end
    expect(second.value).to eq(:performed)

    release.count_down
    expect(first.value).to eq(:performed)

    row = Rafelo::Core::IdempotencyKey.first
    expect(row.status).to eq("succeeded")
    expect(row.outcome).to eq("/en/second")
    expect(row.attempt).to eq(2)
  ensure
    first&.kill
    second&.kill
  end

  it "lets only one of two first claims perform the write" do
    current_session = session
    token = Rafelo::Core::FormToken.issue(session_id: current_session.id)
    controller = controller_for("/en/done")
    entered = latch
    release = latch
    results = Queue.new

    first = Thread.new do
      Rafelo::Core::Current.set(session: current_session) do
        results << Rafelo::Core::IdempotencyClaim.call(controller, token: token, payload: { name: "ada" }, back: "/en/form") do
          entered.count_down
          release.wait(5)
          :ok
        end
      end
    end
    Timeout.timeout(5) { entered.wait }

    second = Thread.new do
      Rafelo::Core::Current.set(session: current_session) do
        results << Rafelo::Core::IdempotencyClaim.call(controller, token: token, payload: { name: "ada" }, back: "/en/form") { :ok }
      end
    end
    second.value
    release.count_down
    first.value

    outcomes = 2.times.map { results.pop }
    expect(outcomes.count(:performed)).to eq(1)
    expect(Rafelo::Core::IdempotencyKey.count).to eq(1)
  ensure
    first&.kill
    second&.kill
  end

  it "loses the exact simultaneous unique insert without performing a second write" do
    current_session = session
    token = Rafelo::Core::FormToken.issue(session_id: current_session.id)
    controller = controller_for("/en/done")
    start = barrier(2)
    results = Queue.new
    threads = 2.times.map do
      Thread.new do
        Rafelo::Core::Current.set(session: current_session) do
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
