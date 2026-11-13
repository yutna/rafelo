require "rails_helper"

RSpec.describe "Example orders pages", type: :request do
  let(:headers) do
    auth_headers(
      grants: %w[
        example_orders:order:read
        example_orders:order:create
        example_orders:order:update
        example_orders:order:export
      ]
    )
  end

  def stub_order_upstream(method, path, fixture)
    stub_request(method, "http://localhost:4000#{path}")
      .with(query: hash_including({}))
      .to_return(
        status: 200,
        body: Rails.root.join("engines/example_orders/spec/fixtures/upstream/orders", fixture).read,
        headers: { "Content-Type" => "application/json" }
      )
  end

  it "proves the index page contract, budgets, URLs and capabilities" do
    stub_order_upstream(:get, "/orders", "index.json")

    expect { get "/en/example_orders/orders?per_page=100", headers: headers }
      .to within_budgets("example_orders/orders/index")

    expect(response).to have_http_status(:ok)
    expect(response).to match_page_schema("example_orders/orders/index")
    expect(response).to be_within_props_budget("example_orders/orders/index")
    expect(response).to have_resolvable_hrefs("example_orders/orders/index")
    expect(response).to match_policy_capabilities("example_orders/orders/index")
  end

  it "proves the show page contract, budgets and URLs" do
    stub_order_upstream(:get, "/orders/order-1", "show.json")

    expect { get "/en/example_orders/orders/order-1", headers: headers }
      .to within_budgets("example_orders/orders/show")

    expect(response).to have_http_status(:ok)
    expect(response).to match_page_schema("example_orders/orders/show")
    expect(response).to be_within_props_budget("example_orders/orders/show")
    expect(response).to have_resolvable_hrefs("example_orders/orders/show")
  end

  it "proves the new page contract, budgets and URLs" do
    expect { get "/en/example_orders/orders/new", headers: headers }
      .to within_budgets("example_orders/orders/new")

    expect(response).to have_http_status(:ok)
    expect(response).to match_page_schema("example_orders/orders/new")
    expect(response).to be_within_props_budget("example_orders/orders/new")
    expect(response).to have_resolvable_hrefs("example_orders/orders/new")
  end

  it "proves the edit page contract, budgets and URLs" do
    stub_order_upstream(:get, "/orders/order-1", "show.json")

    expect { get "/en/example_orders/orders/order-1/edit", headers: headers }
      .to within_budgets("example_orders/orders/edit")

    expect(response).to have_http_status(:ok)
    expect(response).to match_page_schema("example_orders/orders/edit")
    expect(response).to be_within_props_budget("example_orders/orders/edit")
    expect(response).to have_resolvable_hrefs("example_orders/orders/edit")
  end
end
