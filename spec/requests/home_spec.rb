require "rails_helper"

RSpec.describe "Home page", type: :request do
  it "carries the full envelope and the response trace ids" do
    get "/en", headers: auth_headers

    page = JSON.parse(response.body[/<script[^>]*data-page="app"[^>]*>(.*?)<\/script>/m, 1])
    expect(page["props"].keys).to contain_exactly(
      "data", "meta", "query", "pagination", "can", "auth", "app", "nav", "errors", "trace"
    )
    expect(page["props"]["trace"]).to include("requestId", "traceId")
  end

  it "starts a fresh trace while keeping the incoming request id" do
    get "/en", headers: auth_headers.merge("X-Request-Id" => "request-home")

    page = JSON.parse(response.body[/<script[^>]*data-page="app"[^>]*>(.*?)<\/script>/m, 1])
    expect(page.dig("props", "trace", "requestId")).to eq("request-home")
    expect(page.dig("props", "trace", "traceId")).to match(/\A[0-9a-f]{32}\z/)
    expect(page.dig("props", "trace", "traceId")).not_to eq("request-home")
  end

  it "rejects a stale Inertia asset version with 409" do
    get "/en", headers: auth_headers.merge("X-Inertia" => "true", "X-Inertia-Version" => "stale")

    expect(response).to have_http_status(:conflict)
  end

  it "keeps the shared props inside their budget" do
    get "/th", headers: auth_headers
    page = JSON.parse(response.body[/<script[^>]*data-page="app"[^>]*>(.*?)<\/script>/m, 1])
    budget = YAML.load_file(Rails.root.join("config/budgets.yml")).dig("defaults", "shared_props_bytes")

    expect(page.fetch("props").to_json.bytesize).to be <= budget
  end

  it "keeps trace on a partial reload that omits it" do
    get "/en", headers: auth_headers.merge(
      "X-Inertia" => "true",
      "X-Inertia-Version" => Rafelo::Core::AssetVersion.call,
      "X-Inertia-Partial-Component" => "home/index",
      "X-Inertia-Partial-Data" => "data"
    )

    page = JSON.parse(response.body)
    expect(page.dig("props", "data", "message")).to eq("Rafelo")
    expect(page.dig("props", "trace")).to include("requestId", "traceId")
  end

  it "renders the Inertia root with the home component" do
    get "/en", headers: auth_headers

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('id="app"')
    expect(response.body).to include('"component":"home/index"')
    expect(response.body).to include('"message":"Rafelo"')
    expect(response.headers["Cache-Control"]).to include("no-store")
  end
  it "proves the page contract, budgets, URLs and capabilities" do
    expect { get "/en", headers: auth_headers }.to within_budgets("home/index")
    expect(response).to match_page_schema("home/index")
    expect(response).to be_within_props_budget("home/index")
    expect(response).to have_resolvable_hrefs("home/index")
    expect(response).to match_policy_capabilities("home/index")
  end
end
