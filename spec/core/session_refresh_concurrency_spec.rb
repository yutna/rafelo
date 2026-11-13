require "rails_helper"
require "timeout"

RSpec.describe "Session refresh concurrency", :concurrency, truncate: %w[core_sessions] do
  self.use_transactional_tests = false

  it "makes one upstream refresh and gives both callers the winner token" do
    viewer = Struct.new(:id, :name).new(7, "Ada")
    session, = Rafelo::Core::Session.start(
      viewer: viewer, access_token: "old-access", refresh_token: "old-refresh",
      access_expires_at: 10.seconds.from_now, grants: [ "billing:invoice:read" ]
    )
    session.update_column(:grants_refreshed_at, 10.minutes.ago)

    entered = Queue.new
    release = Queue.new
    calls = 0
    mutex = Mutex.new
    gateway = Class.new do
      define_method(:refresh) do |refresh_token:|
        mutex.synchronize { calls += 1 }
        entered << true
        release.pop
        Rafelo::Core::AuthGateway::Result.new(
          viewer: viewer,
          access_token: "winner-access",
          refresh_token: "winner-refresh",
          access_expires_at: 5.minutes.from_now,
          grants: [ "billing:invoice:create" ]
        )
      end
    end.new

    first = Rafelo::Core::Session.find(session.id)
    second = Rafelo::Core::Session.find(session.id)
    first_thread = Thread.new { Rafelo::Core::SessionRefresher.new(session: first, gateway: gateway, timeout: 0).call }
    Timeout.timeout(5) { entered.pop }

    waited = Queue.new
    subscriber = ActiveSupport::Notifications.subscribe("session_refresh.wait") { waited << true }
    second_thread = Thread.new { Rafelo::Core::SessionRefresher.new(session: second, gateway: gateway, timeout: 0).call }
    Timeout.timeout(5) { waited.pop }

    release << true
    tokens = [ first_thread.value, second_thread.value ]

    expect(tokens).to eq([ "winner-access", "winner-access" ])
    expect(mutex.synchronize { calls }).to eq(1)
    expect(Rafelo::Core::Session.find(session.id).permission_grants).to eq([ "billing:invoice:create" ])
  ensure
    ActiveSupport::Notifications.unsubscribe(subscriber) if subscriber
    first_thread&.kill
    second_thread&.kill
  end
end
