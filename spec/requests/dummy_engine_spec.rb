require "rails_helper"

RSpec.describe "Dummy engine", type: :request do
  def page_body
    get "/en/dummy/widgets"
    JSON.parse(response.body[/<script[^>]*data-page="app"[^>]*>(.*?)<\/script>/m, 1])
  end

  it "renders the full envelope through a test-only engine" do
    page = page_body

    expect(response).to have_http_status(:ok)
    expect(page.dig("props", "data", "message")).to eq("dummy")
    expect(page["props"].keys).to contain_exactly(
      "data", "meta", "query", "pagination", "can", "auth", "app", "nav", "errors", "trace"
    )
  end

  it "raises when a page key is missing or a shared key is added" do
    expect { get "/en/dummy/missing_key" }.to raise_error(ArgumentError, /page props must be exactly/)
    expect { get "/en/dummy/extra_key" }.to raise_error(ArgumentError, /page props must be exactly/)
  end

  it "renders the shared error page for a denial" do
    get "/th/dummy/denied", headers: { "X-Inertia" => "true", "X-Inertia-Version" => Rafelo::Core::AssetVersion.call }

    expect(response).to have_http_status(:forbidden)
    expect(JSON.parse(response.body).dig("props", "data", "code")).to eq("auth.forbidden")
  end

  it "carries translated flash at the page level, never in props" do
    get "/en/dummy/flash"
    expect(response).to have_http_status(:see_other)

    get "/en/dummy/widgets"
    page = JSON.parse(response.body[/<script[^>]*data-page="app"[^>]*>(.*?)<\/script>/m, 1])
    expect(page.dig("flash", "notice")).to eq("Dummy notice")
    expect(page["props"]).not_to have_key("flash")
  end
end
