require "rails_helper"

RSpec.describe "Home page", type: :request do
  it "carries the full envelope and the response trace ids" do
    get "/en"

    page = JSON.parse(response.body[/<script data-page="app" type="application\/json">(.*?)<\/script>/m, 1])
    expect(page["props"].keys).to contain_exactly(
      "data", "meta", "query", "pagination", "can", "auth", "app", "nav", "errors", "trace"
    )
    expect(page["props"]["trace"]).to include("requestId", "traceId")
  end

  it "keeps trace on a partial reload that omits it" do
    get "/en", headers: {
      "X-Inertia" => "true",
      "X-Inertia-Version" => Rafelo::Core::AssetVersion.call,
      "X-Inertia-Partial-Component" => "home/index",
      "X-Inertia-Partial-Data" => "data"
    }

    page = JSON.parse(response.body)
    expect(page.dig("props", "data", "message")).to eq("Rafelo")
    expect(page.dig("props", "trace")).to include("requestId", "traceId")
  end

  it "renders the Inertia root with the home component" do
    get "/en"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('id="app"')
    expect(response.body).to include('"component":"home/index"')
    expect(response.body).to include('"message":"Rafelo"')
    expect(response.headers["Cache-Control"]).to include("no-store")
  end
end
