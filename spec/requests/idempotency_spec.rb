require "rails_helper"

RSpec.describe "Idempotent writes", type: :request do
  def page_body(response)
    JSON.parse(response.body[/<script[^>]*data-page="app"[^>]*>(.*?)<\/script>/m, 1])
  end

  def signed_in_cookie(viewer_id = 7)
    viewer = Struct.new(:id, :name).new(viewer_id, "Ada")
    _, token = Rafelo::Core::Session.start(
      viewer: viewer, access_token: "access", refresh_token: "refresh",
      access_expires_at: 5.minutes.from_now, grants: []
    )
    "session_token=#{token}"
  end

  def follow(cookie)
    location = response.location
    rails = Array(response.headers["Set-Cookie"]).filter_map do |value|
      value.split(";").first if value.start_with?("rafelo_session=")
    end.first
    get location, headers: { "Cookie" => [ cookie, rails ].compact.join("; ") }
  end

  def token_for(cookie)
    get "/en/dummy/widgets", headers: { "Cookie" => cookie }
    page_body(response).dig("props", "meta", "formToken")
  end

  def submit(cookie, token, name: "ada")
    post "/en/dummy/widgets", params: { name: name, token: token }, headers: { "Cookie" => cookie }
  end

  it "replays a succeeded redirect without calling the upstream again" do
    cookie = signed_in_cookie
    token = token_for(cookie)
    submit(cookie, token)
    expect(response).to have_http_status(:see_other)
    expect(Rafelo::Core::IdempotencyKey.count).to eq(1)

    submit(cookie, token)

    expect(response).to have_http_status(:see_other)
    expect(Rafelo::Core::IdempotencyKey.count).to eq(1)
    expect(Rafelo::Core::IdempotencyKey.first.status).to eq("succeeded")
  end

  it "refuses an edited resubmit of the same token" do
    cookie = signed_in_cookie
    token = token_for(cookie)
    submit(cookie, token, name: "ada")

    submit(cookie, token, name: "bob")
    expect(response).to have_http_status(:see_other)
    follow(cookie)
    expect(page_body(response).dig("props", "errors", "base")).to include("not valid")
    expect(Rafelo::Core::IdempotencyKey.count).to eq(1)
  end

  it "refuses a token issued for another session" do
    first = signed_in_cookie(7)
    second = signed_in_cookie(8)
    token = token_for(first)

    submit(second, token)

    expect(response).to have_http_status(:see_other)
    follow(second)
    expect(page_body(response).dig("props", "errors", "base")).to include("not valid")
  end

  it "refuses an unknown outcome without replaying it" do
    cookie = signed_in_cookie
    token = token_for(cookie)
    submit(cookie, token)
    Rafelo::Core::IdempotencyKey.update_all(status: "unknown", outcome: nil)

    submit(cookie, token)

    follow(cookie)
    expect(page_body(response).dig("props", "errors", "base")).to include("could not confirm")
  end

  it "answers still processing for a fresh pending row" do
    cookie = signed_in_cookie
    token = token_for(cookie)
    submit(cookie, token)
    Rafelo::Core::IdempotencyKey.update_all(status: "pending", outcome: nil, claimed_at: Time.current)

    submit(cookie, token)

    follow(cookie)
    expect(page_body(response).dig("props", "errors", "base")).to include("still processing")
  end

  it "takes over a failed row and increments the attempt" do
    cookie = signed_in_cookie
    token = token_for(cookie)
    submit(cookie, token)
    Rafelo::Core::IdempotencyKey.update_all(status: "failed", outcome: nil)

    submit(cookie, token)

    expect(response).to have_http_status(:see_other)
    row = Rafelo::Core::IdempotencyKey.first
    expect(row.status).to eq("succeeded")
    expect(row.attempt).to eq(2)
  end
end
