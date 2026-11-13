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
end
