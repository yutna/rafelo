require "rails_helper"

RSpec.describe "Session flow", type: :request do
  before do
    stub_upstream(:post, "/auth/sign_in", fixture: "auth/sign_in.json", base_url: "http://localhost:4000")
  end

  it "signs in, loads the viewer and signs out" do
    post "/en/sign_in", params: { email: "ada@example.test", password: "secret" }

    expect(response).to have_http_status(:see_other)
    expect(response.location).to end_with("/en")
    cookie = Array(response.headers["Set-Cookie"]).join("\n").split(";").first
    expect(Array(response.headers["Set-Cookie"]).join("\n")).to match(/httponly/i)
    expect(Array(response.headers["Set-Cookie"]).join("\n")).to match(/samesite=lax/i)
    expect(Rafelo::Core::Session.count).to eq(1)
    expect(Rafelo::Core::Session.first.permission_grants).to eq([ "billing:invoice:read" ])

    get "/en/dummy/whoami", headers: { "Cookie" => cookie }
    expect(response.body).to eq("7")

    get "/en", headers: { "Cookie" => cookie }
    expect(response).to have_http_status(:ok)
    expect(response.body).to include('"message":"Rafelo"')

    delete "/en/sign_out", headers: { "Cookie" => cookie }
    expect(response).to have_http_status(:see_other)
    expect(Rafelo::Core::Session.count).to eq(0)
  end

  it "renders the sign-in page with the form" do
    get "/en/sign_in"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('"component":"sessions/new"')
  end
end

RSpec.describe "Session refresh and expiry", type: :request do
  let(:viewer) { Struct.new(:id, :name).new(7, "Ada") }


  def session_with(expires_at: 5.minutes.from_now, grants_at: Time.current)
    session, token = Rafelo::Core::Session.start(
      viewer: viewer, access_token: "old-access", refresh_token: "old-refresh",
      access_expires_at: expires_at, grants: [ "billing:invoice:read" ]
    )
    session.update_column(:grants_refreshed_at, grants_at)
    [ session, "session_token=#{token}" ]
  end

  it "refreshes tokens and grants through the single-flight path" do
    stub_upstream(:post, "/auth/refresh", fixture: "auth/refresh.json", base_url: "http://localhost:4000")
    session, cookie = session_with(expires_at: 10.seconds.from_now, grants_at: 10.minutes.ago)

    get "/en", headers: { "Cookie" => cookie }

    expect(response).to have_http_status(:ok)
    session.reload
    expect(session.access_token).to eq("fresh-access")
    expect(session.permission_grants).to include("billing:invoice:create")
  end

  it "clears the cookie and redirects to sign-in for a dead session error" do
    session, cookie = session_with
    get "/en/dummy/expired", headers: { "Cookie" => cookie }

    expect(response).to have_http_status(:see_other)
    expect(response.location).to end_with("/en/sign_in")
    expect(Rafelo::Core::Session.exists?(session.id)).to be(false)
  end

  it "clears the cookie and redirects to sign-in when refresh detects a dead session" do
    stub_upstream(:post, "/auth/refresh", fixture: "auth/expired.json", status: 401, base_url: "http://localhost:4000")
    session, cookie = session_with(expires_at: 10.seconds.from_now, grants_at: 10.minutes.ago)

    get "/en", headers: { "Cookie" => cookie }

    expect(response).to have_http_status(:see_other)
    expect(response.location).to end_with("/en/sign_in")
    expect(Rafelo::Core::Session.exists?(session.id)).to be(false)
    expect(Array(response.headers["Set-Cookie"]).join("\n")).to include("session_token=;")
  end

  it "forgets an idle session and clears its cookie" do
    session, cookie = session_with
    session.update_column(:last_seen_at, 31.minutes.ago)

    get "/en", headers: { "Cookie" => cookie }

    expect(response).to have_http_status(:ok)
    expect(Rafelo::Core::Session.exists?(session.id)).to be(false)
    expect(Array(response.headers["Set-Cookie"]).join("\n")).to include("session_token=;")
  end

  it "forgets an expired session and clears its cookie" do
    session, cookie = session_with
    session.update_column(:expires_at, 1.minute.ago)

    get "/en", headers: { "Cookie" => cookie }

    expect(Rafelo::Core::Session.exists?(session.id)).to be(false)
    expect(Array(response.headers["Set-Cookie"]).join("\n")).to include("session_token=;")
  end
end

RSpec.describe "Session lifecycle edges", type: :request do
  let(:viewer) { Struct.new(:id, :name).new(7, "Ada") }

  def session_with(last_seen_at: Time.current, expires_at: 5.minutes.from_now)
    session, token = Rafelo::Core::Session.start(
      viewer: viewer, access_token: "access", refresh_token: "refresh",
      access_expires_at: expires_at, grants: [ "billing:invoice:read" ]
    )
    session.update_column(:last_seen_at, last_seen_at)
    [ session, "session_token=#{token}" ]
  end

  before do
    stub_upstream(:post, "/auth/sign_in", fixture: "auth/sign_in.json", base_url: "http://localhost:4000")
  end

  it "keeps the other session on normal sign-out and revokes all on sign-out everywhere" do
    _, first = session_with
    _, second = session_with
    expect(Rafelo::Core::Session.count).to eq(2)

    delete "/en/sign_out", headers: { "Cookie" => first }
    expect(response).to have_http_status(:see_other)

    expect(Rafelo::Core::Session.count).to eq(1)
    expect(Array(response.headers["Set-Cookie"]).join("\n")).to include("session_token=;")

    delete "/en/sign_out_everywhere", headers: { "Cookie" => second }
    expect(response).to have_http_status(:see_other)
    expect(Rafelo::Core::Session.count).to eq(0)
  end

  it "touches last_seen_at at most once per interval" do
    session, cookie = session_with(last_seen_at: 2.minutes.ago)
    seen = session.last_seen_at

    get "/en", headers: { "Cookie" => cookie }

    expect(session.reload.last_seen_at).to be_within(1.second).of(seen)
  end

  it "touches last_seen_at after the interval" do
    session, cookie = session_with(last_seen_at: 6.minutes.ago)

    get "/en", headers: { "Cookie" => cookie }

    expect(session.reload.last_seen_at).to be_within(5.seconds).of(Time.current)
  end

  it "keeps the session just inside the idle timeout and ends it just after" do
    live, live_cookie = session_with(last_seen_at: 29.minutes.ago)
    get "/en", headers: { "Cookie" => live_cookie }
    expect(Rafelo::Core::Session.exists?(live.id)).to be(true)

    idle, idle_cookie = session_with(last_seen_at: 30.minutes.ago - 1.second)
    get "/en", headers: { "Cookie" => idle_cookie }
    expect(Rafelo::Core::Session.exists?(idle.id)).to be(false)
    expect(Array(response.headers["Set-Cookie"]).join("\n")).to include("session_token=;")
  end

  it "keeps the old token when a refresh fails transiently" do
    stub_upstream(:post, "/auth/refresh", fixture: "auth/expired.json", status: 503, base_url: "http://localhost:4000")
    session, cookie = session_with(expires_at: 10.seconds.from_now)

    get "/en", headers: { "Cookie" => cookie }

    expect(response).to have_http_status(:ok)
    expect(Rafelo::Core::Session.exists?(session.id)).to be(true)
    expect(session.reload.access_token).to eq("access")
  end
end
