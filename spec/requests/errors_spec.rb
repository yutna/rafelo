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

  it "renders a router 404 under Thai with both ids and no-store" do
    get "/th/missing-page"

    expect(response).to have_http_status(:not_found)
    body = JSON.parse(response.body).fetch("error")
    expect(body["code"]).to eq("resource.not_found")
    expect(body["message"]).to include("ไม่พบ")
    expect(body["requestId"]).to be_present
    expect(body["traceId"]).to be_present
    expect(response.headers["Cache-Control"]).to include("no-store")
  end
  it "proves the error page contract" do
    expect { get "/en/dummy/widgets/not_found", headers: { "X-Inertia" => "true", "X-Inertia-Version" => Rafelo::Core::AssetVersion.call } }.to within_budgets("errors/show")

    expect(response).to have_http_status(:not_found)
    expect(response).to match_page_schema("errors/show")
    expect(response).to be_within_props_budget("errors/show")
    expect(response).to have_resolvable_hrefs("errors/show")
    expect(response).to match_policy_capabilities("errors/show")
  end
end
