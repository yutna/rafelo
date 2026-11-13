require "rails_helper"

RSpec.describe "Request throttling", type: :request do
  before do
    stub_upstream(:post, "/auth/sign_in", fixture: "auth/sign_in.json", base_url: "http://localhost:4000")
  end

  it "answers request.throttled after the sign-in limit" do
    10.times do
      post "/en/sign_in", params: { email: "ada@example.test", password: "secret" }
      expect(response).not_to have_http_status(:too_many_requests)
    end

    post "/en/sign_in", params: { email: "ada@example.test", password: "secret" }

    expect(response).to have_http_status(:too_many_requests)
    expect(response.body).to include("request.throttled")
    expect(response.headers["Cache-Control"]).to include("no-store")
  end
end
