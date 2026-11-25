require "rails_helper"

RSpec.describe "Error responder", type: :request do
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

  def page_from(body)
    JSON.parse(body[/<script[^>]*data-page="app"[^>]*>(.*?)<\/script>/m, 1])
  end

  def expect_error_page(response, code: "resource.not_found", message: "ไม่พบ")
    expect(response).to have_http_status(:not_found)
    page = page_from(response.body)
    expect(page["component"]).to eq("errors/show")
    expect(page.dig("props", "data", "code")).to eq(code)
    expect(page.dig("props", "data", "message")).to include(message)
    expect(page.dig("props", "data", "requestId")).to be_present
    expect(page.dig("props", "data", "traceId")).to be_present
    expect(response.headers["Cache-Control"]).to include("no-store")
    expect(response.headers["Content-Security-Policy"]).to be_present
  end

  it "renders a router 404 under Thai as the HTML error page" do
    get "/th/missing-page"

    expect_error_page(response)
  end

  it "renders a router 404 under Thai for an Inertia visit" do
    get "/th/missing-page",
        headers: { "X-Inertia" => "true", "X-Inertia-Version" => Rafelo::Core::AssetVersion.call }

    expect(response).to have_http_status(:not_found)
    body = JSON.parse(response.body)
    expect(body["component"]).to eq("errors/show")
    expect(body.dig("props", "data", "message")).to include("ไม่พบ")
    expect(body.dig("props", "data", "requestId")).to be_present
    expect(response.headers["Cache-Control"]).to include("no-store")
    expect(response.headers["Content-Security-Policy"]).to be_present
  end

  it "renders a router 404 under Thai as JSON for a non-Inertia caller" do
    get "/th/missing-page", headers: { "Accept" => "application/json" }

    expect(response).to have_http_status(:not_found)
    body = JSON.parse(response.body).fetch("error")
    expect(body["code"]).to eq("resource.not_found")
    expect(body["message"]).to include("ไม่พบ")
    expect(body["requestId"]).to be_present
    expect(body["traceId"]).to be_present
    expect(response.headers["Cache-Control"]).to include("no-store")
    expect(response.headers["Content-Security-Policy"]).to be_present
  end

  it "renders a missing parameter as the error page, Inertia, and JSON" do
    get "/th/dummy/widgets/parameter_missing"
    expect(response).to have_http_status(:bad_request)
    page = page_from(response.body)
    expect(page["component"]).to eq("errors/show")
    expect(page.dig("props", "data", "code")).to eq("request.invalid")
    expect(page.dig("props", "data", "message")).to be_present
    expect(response.headers["Cache-Control"]).to include("no-store")
    expect(response.headers["Content-Security-Policy"]).to be_present

    get "/th/dummy/widgets/parameter_missing",
        headers: { "X-Inertia" => "true", "X-Inertia-Version" => Rafelo::Core::AssetVersion.call }
    expect(response).to have_http_status(:bad_request)
    expect(JSON.parse(response.body)["component"]).to eq("errors/show")

    get "/th/dummy/widgets/parameter_missing", headers: { "Accept" => "application/json" }
    expect(response).to have_http_status(:bad_request)
    expect(JSON.parse(response.body).dig("error", "code")).to eq("request.invalid")
  end

  it "audits an unhandled non-GET failure exactly once" do
    post "/en/dummy/widgets/crash", headers: auth_headers

    expect(response).to have_http_status(:internal_server_error)
    expect(Rafelo::Core::AuditEvent.where(event: "write", outcome: "failure").count).to eq(1)
  end

  it "renders an unhandled failure as the HTML error page under Thai" do
    expect { post "/th/dummy/widgets/crash", headers: auth_headers }.not_to raise_error

    expect(response).to have_http_status(:internal_server_error)
    expect(response.media_type).to eq("text/html")
    page = page_from(response.body)
    expect(page["component"]).to eq("errors/show")
    expect(page.dig("props", "data", "code")).to eq("unexpected")
    expect(page.dig("props", "data", "message")).to be_present
    expect(response.headers["Cache-Control"]).to include("no-store")
    expect(response.headers["Content-Security-Policy"]).to be_present
  end

  it "proves the error page contract" do
    expect { get "/en/dummy/widgets/not_found", headers: auth_headers.merge("X-Inertia" => "true", "X-Inertia-Version" => Rafelo::Core::AssetVersion.call) }.to within_budgets("errors/show")

    expect(response).to have_http_status(:not_found)
    expect(response).to match_page_schema("errors/show")
    expect(response).to be_within_props_budget("errors/show")
    expect(response).to have_resolvable_hrefs("errors/show")
    expect(response).to match_policy_capabilities("errors/show")
  end
end
