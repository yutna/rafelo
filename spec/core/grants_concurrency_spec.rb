require "rails_helper"

RSpec.describe "Grants generation concurrency", :concurrency, truncate: %w[core_sessions] do
  self.use_transactional_tests = false

  it "does not let a re-fetch started before a 403 clear the mark" do
    viewer = Struct.new(:id, :name).new(7, "Ada")
    session, = Rafelo::Core::Session.start(
      viewer: viewer, access_token: "access", refresh_token: "refresh",
      access_expires_at: 5.minutes.from_now, grants: [ "billing:invoice:read" ]
    )
    started = Queue.new
    proceed = Queue.new
    result = nil
    thread = Thread.new do
      ActiveRecord::Base.connection_pool.with_connection do
        copy = Rafelo::Core::Session.find(session.id)
        generation = copy.grants_generation
        started << true
        proceed.pop
        result = copy.replace_grants!([ "billing:invoice:create" ], generation: generation)
      end
    end

    started.pop
    Rafelo::Core::Session.find(session.id).mark_grants_stale!
    proceed << true
    thread.value

    expect(result).to be(false)
    reloaded = Rafelo::Core::Session.find(session.id)
    expect(reloaded.permission_grants).to eq([ "billing:invoice:read" ])
    expect(reloaded.grants_stale?).to be(true)
  ensure
    thread&.kill
  end
end
