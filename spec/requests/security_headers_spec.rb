require "rails_helper"

RSpec.describe "Security headers", type: :request do
  it "sets the security headers and a nonce-based CSP" do
    get "/en", headers: auth_headers

    expect(response.headers["X-Frame-Options"]).to eq("DENY")
    expect(response.headers["X-Content-Type-Options"]).to eq("nosniff")
    expect(response.headers["Referrer-Policy"]).to eq("strict-origin-when-cross-origin")
    expect(response.headers["Content-Security-Policy"]).to include("default-src 'self'")
    expect(response.headers["Content-Security-Policy"]).to match(/script-src 'self' 'nonce-[^']+'/)
    expect(response.headers["Content-Security-Policy"]).not_to include("'nonce-'")
    expect(response.headers["Content-Security-Policy"]).to include("frame-ancestors 'none'")
    expect(response.headers["Content-Security-Policy"]).to include("form-action 'self'")
    expect(response.headers["Permissions-Policy"]).to eq("camera=(), geolocation=(), microphone=()")
    expect(response.body).to match(/<meta name="csp-nonce" content="[^"]+">/)
    expect(response.headers["Content-Security-Policy"]).not_to include("unsafe-inline")
  end

  it "rejects an unverified write and accepts the form token" do
    stub_upstream(:post, "/auth/sign_in", fixture: "auth/sign_in.json", base_url: "http://localhost:4000")
    previous = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
    get "/en/sign_in"
    page = JSON.parse(response.body[/<script[^>]*data-page="app"[^>]*>(.*?)<\/script>/m, 1])
    token = page.dig("props", "meta", "csrfToken")
    expect(token).to be_present

    post "/en/sign_in", params: { email: "a@example.test", password: "secret" }
    expect(response).to have_http_status(:unprocessable_content)

    post "/en/sign_in", params: { email: "a@example.test", password: "secret", authenticity_token: token }
    expect(response).to have_http_status(:see_other)
  ensure
    ActionController::Base.allow_forgery_protection = previous
  end

  it "keeps the headers on a 403 and a router 404" do
    viewer = Struct.new(:id, :name).new(7, "Ada")
    session, token = Rafelo::Core::Session.start(
      viewer: viewer, access_token: "access", refresh_token: "refresh",
      access_expires_at: 5.minutes.from_now, grants: []
    )

    get "/en/dummy/denied", headers: { "Cookie" => "session_token=#{token}" }
    expect(response).to have_http_status(:forbidden)
    expect(response.headers["Content-Security-Policy"]).to include("form-action 'self'")
    expect(response.headers["Permissions-Policy"]).to eq("camera=(), geolocation=(), microphone=()")

    get "/en/does-not-exist"
    expect(response).to have_http_status(:not_found)
    expect(response.headers["Permissions-Policy"]).to eq("camera=(), geolocation=(), microphone=()")
  ensure
    session&.destroy
  end

  it "throttles repeated sign-in attempts" do
    stub_upstream(:post, "/auth/sign_in", fixture: "auth/sign_in.json", base_url: "http://localhost:4000")
    11.times do
      post "/th/sign_in", params: { email: "a@example.test", password: "wrong" }
    end

    expect(response).to have_http_status(:too_many_requests)
  end
end
