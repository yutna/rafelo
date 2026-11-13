require "rails_helper"

RSpec.describe "Locale routing", type: :request do
  it "redirects an unprefixed GET to the default locale" do
    get "/"

    expect(response).to have_http_status(:found)
    expect(response.location).to end_with("/en")
  end

  it "renders the locale-prefixed page in English" do
    get "/en", headers: auth_headers

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('"message":"Rafelo"')
  end

  it "renders the locale-prefixed page in Thai" do
    get "/th", headers: auth_headers

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("ราฟีโล")
  end

  it "keeps the health check exempt" do
    get "/up"

    expect(response).to have_http_status(:ok)
  end

  it "returns 404 for an unavailable locale" do
    get "/fr"

    expect(response).to have_http_status(:not_found)
  end
end
