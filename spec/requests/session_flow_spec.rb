require "rails_helper"

RSpec.describe "Session flow", type: :request do
  before do
    stub_upstream(:post, "/auth/sign_in", fixture: "auth/sign_in.json", base_url: "http://localhost:4000")
  end

  it "signs in, loads the viewer and signs out" do
    post "/en/sign_in", params: { email: "ada@example.test", password: "secret" }

    expect(response).to have_http_status(:see_other)
    expect(response.location).to end_with("/en")
    cookie = response.headers["Set-Cookie"].split(";").first
    expect(response.headers["Set-Cookie"]).to match(/httponly/i)
    expect(response.headers["Set-Cookie"]).to match(/samesite=lax/i)
    expect(Rafelo::Core::Session.count).to eq(1)
    expect(Rafelo::Core::Session.first.permission_grants).to eq([ "billing:invoice:read" ])

    get "/en/dummy/whoami", headers: { "Cookie" => cookie }
    expect(response.body).to eq("7")

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
