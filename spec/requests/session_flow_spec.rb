require "rails_helper"

RSpec.describe "Session flow", type: :request do
  before do
    Rack::Attack.reset!
    stub_upstream(:post, "/auth/sign_in", fixture: "auth/sign_in.json", base_url: "http://localhost:4000")
  end

  it "signs in, loads the viewer and signs out" do
    post "/en/sign_in", params: { email: "ada@example.test", password: "secret" }

    expect(response).to have_http_status(:see_other)
    expect(response.location).to end_with("/en")
    cookie = response.headers["Set-Cookie"].join("\n").split(";").first
    expect(response.headers["Set-Cookie"].join("\n")).to match(/httponly/i)
    expect(response.headers["Set-Cookie"].join("\n")).to match(/samesite=lax/i)
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

  before { Rack::Attack.reset! }

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
end
