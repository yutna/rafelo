require "rails_helper"

RSpec.describe "Component catalog", type: :request do
  it "renders the development catalog with the page contract and budgets" do
    expect { get "/en/component_catalog", headers: auth_headers }.to within_budgets("component_catalog/index")

    expect(response).to have_http_status(:ok)
    expect(response).to match_page_schema("component_catalog/index")
    expect(response).to be_within_props_budget("component_catalog/index")
    expect(response).to have_resolvable_hrefs("component_catalog/index")
    expect(response).to match_policy_capabilities("component_catalog/index")
  end
end
