require "rails_helper"

RSpec.describe "Audited outcomes", type: :request do
  def page_body(response)
    JSON.parse(response.body[/<script[^>]*data-page="app"[^>]*>(.*?)<\/script>/m, 1])
  end

  def form_token(cookie)
    get "/en/dummy/widgets", headers: { "Cookie" => cookie }
    page_body(response).dig("props", "meta", "formToken")
  end

  def rows(event = nil)
    scope = Rafelo::Core::AuditEvent.all
    scope = scope.where(event: event) if event
    scope
  end

  it "records one successful write row with the resource and action" do
    cookie = sign_in_cookie
    post "/en/dummy/widgets", params: { name: "ada", token: form_token(cookie) }, headers: { "Cookie" => cookie }

    expect(response).to have_http_status(:see_other)
    expect(rows("write").count).to eq(1)
    event = rows("write").last
    expect(event.outcome).to eq("success")
    expect(event.resource).to eq("dummy_engine/widgets")
    expect(event.action).to eq("create")
  end

  it "records one failure row for a shape error, a conflict, and an upstream 503" do
    cookie = sign_in_cookie

    post "/en/dummy/widgets", params: { name: "" }, headers: { "Cookie" => cookie }
    expect(rows("write").count).to eq(1)
    expect(rows("write").last.outcome).to eq("failure")

    post "/en/dummy/widgets/conflict", headers: { "Cookie" => cookie }
    expect(rows("write").count).to eq(2)
    expect(rows("write").last.outcome).to eq("failure")

    stub_upstream(:post, "/widgets", fixture: "widgets/error.json", status: 503, base_url: "http://localhost:4000")
    post "/en/dummy/widgets/upstream", headers: { "Cookie" => cookie }

    expect(rows("write").count).to eq(3)
    expect(rows("write").last.outcome).to eq("failure")
  end

  it "records a write refused with 403 as the denial and not a second row" do
    post "/en/dummy/denied", headers: auth_headers

    expect(response).to have_http_status(:forbidden)
    expect(rows("authorization").count).to eq(1)
    expect(rows("write").count).to eq(0)
    event = rows("authorization").last
    expect(event.policy).to be_present
    expect(event.page).to be_present
  end

  it "records sign-in failure" do
    stub_upstream(:post, "/auth/sign_in", fixture: "auth/sign_in.json", status: 401, base_url: "http://localhost:4000")

    post "/en/sign_in", params: { email: "ada@example.test", password: "secret" }

    expect(rows("sign_in").count).to eq(1)
    expect(rows("sign_in").last.outcome).to eq("failure")
  end

  it "records no write row for a GET that fails upstream" do
    stub_upstream(:get, "/forbidden", fixture: "widgets/error.json", status: 503, base_url: "http://localhost:4000")

    get "/en/dummy/widgets/upstream_forbidden", headers: auth_headers

    expect(response).to have_http_status(:service_unavailable)
    expect(rows("write").count).to eq(0)
  end

  it "records a denial once and no second write row" do
    get "/en/dummy/denied", headers: auth_headers

    expect(response).to have_http_status(:forbidden)
    expect(rows("authorization").count).to eq(1)
    expect(rows("write").count).to eq(0)
  end

  around do |example|
    previous = Rails.application.env_config["action_dispatch.show_exceptions"]
    previous_detailed = Rails.application.env_config["action_dispatch.show_detailed_exceptions"]
    Rails.application.env_config["action_dispatch.show_exceptions"] = :all
    Rails.application.env_config["action_dispatch.show_detailed_exceptions"] = false
    example.run
  ensure
    Rails.application.env_config["action_dispatch.show_exceptions"] = previous
    Rails.application.env_config["action_dispatch.show_detailed_exceptions"] = previous_detailed
  end

  it "records an unhandled write failure once" do
    post "/en/dummy/widgets/crash", headers: auth_headers

    expect(response).to have_http_status(:internal_server_error)
    expect(rows("write").count).to eq(1)
  end

  it "records an auth rate limit hit" do
    stub_upstream(:post, "/auth/sign_in", fixture: "auth/sign_in.json", base_url: "http://localhost:4000")

    11.times do
      post "/en/sign_in", params: { email: "ada@example.test", password: "secret" }
    end

    expect(response).to have_http_status(:too_many_requests)
    expect(rows("rate_limit").count).to eq(1)
  end

  it "records a session revoked by a refresh 401" do
    stub_upstream(:post, "/auth/refresh", fixture: "auth/expired.json", status: 401, base_url: "http://localhost:4000")
    viewer = Struct.new(:id, :name).new(7, "Ada")
    _, token = Rafelo::Core::Session.start(
      viewer: viewer,
      access_token: "old-access",
      refresh_token: "old-refresh",
      access_expires_at: 10.seconds.from_now
    )
    Rafelo::Core::Session.last.update_column(:grants_refreshed_at, 10.minutes.ago)

    get "/en", headers: { "Cookie" => "session_token=#{token}" }

    expect(response).to have_http_status(:see_other)
    expect(rows("session_revoked").count).to eq(1)
  end

  it "records no write row for a session-less endpoint", :csrf do
    get "/en/sign_in"
    session_cookie = Array(response.headers["Set-Cookie"]).flat_map { |header| header.split("\n") }
      .find { |value| value.start_with?("rafelo_session=") }

    post "/core/client_errors",
         params: { message: "boom", path: "/en", release: "a" * 40 }.to_json,
         headers: {
           "Content-Type" => "application/json",
           "X-CSRF-Token" => csrf_token_from_response,
           "Cookie" => session_cookie&.split(";")&.first
         }.compact

    expect(response).to have_http_status(:no_content)
    expect(rows("write").count).to eq(0)
  end
end
