require_relative "../rails_helper"

RSpec.describe "Example orders", type: :request do
  let(:grants) do
    %w[
      example_orders:order:read
      example_orders:order:create
      example_orders:order:update
      example_orders:order:export
    ]
  end
  let(:headers) { auth_headers(grants: grants) }

  def stub_order_upstream(method, path, fixture, status: 200)
    stub_request(method, "http://localhost:4000#{path}")
      .with(query: hash_including({}))
      .to_return(
        status: status,
        body: Rails.root.join("engines/example_orders/spec/fixtures/upstream/orders", fixture).read,
        headers: { "Content-Type" => "application/json" }
      )
  end

  def page_body
    JSON.parse(response.body[/<script[^>]*data-page="app"[^>]*>(.*?)<\/script>/m, 1])
  end

  it "renders the filtered, paginated index through the full page contract" do
    stub_order_upstream(:get, "/orders", "index.json")

    expect { get "/en/example_orders/orders?per_page=100&status=open", headers: headers }
      .to within_budgets("example_orders/orders/index")

    expect(response).to have_http_status(:ok)
    expect(response).to match_page_schema("example_orders/orders/index")
    expect(response).to be_within_props_budget("example_orders/orders/index")
    expect(response).to have_resolvable_hrefs("example_orders/orders/index")
    expect(response).to match_policy_capabilities("example_orders/orders/index")
  end

  it "renders the show page" do
    stub_order_upstream(:get, "/orders/order-1", "show.json")

    expect { get "/en/example_orders/orders/order-1", headers: headers }
      .to within_budgets("example_orders/orders/show")

    expect(response).to have_http_status(:ok)
    expect(response).to match_page_schema("example_orders/orders/show")
    expect(response).to be_within_props_budget("example_orders/orders/show")
    expect(response).to have_resolvable_hrefs("example_orders/orders/show")
  end

  it "renders new and edit with the form token and the full page contract" do
    expect { get "/en/example_orders/orders/new", headers: headers }
      .to within_budgets("example_orders/orders/new")
    expect(response).to have_http_status(:ok)
    expect(response).to match_page_schema("example_orders/orders/new")
    expect(response).to be_within_props_budget("example_orders/orders/new")
    expect(response).to have_resolvable_hrefs("example_orders/orders/new")
    expect(page_body.dig("props", "meta", "formToken")).to be_present

    stub_order_upstream(:get, "/orders/order-1", "show.json")
    expect { get "/en/example_orders/orders/order-1/edit", headers: headers }
      .to within_budgets("example_orders/orders/edit")
    expect(response).to have_http_status(:ok)
    expect(response).to match_page_schema("example_orders/orders/edit")
    expect(response).to be_within_props_budget("example_orders/orders/edit")
    expect(response).to have_resolvable_hrefs("example_orders/orders/edit")
    expect(page_body.dig("props", "meta", "formToken")).to be_present
    expect(page_body.dig("props", "data", "order", "version")).to eq(1)
  end


  it "keeps page size and sort in pagination and filter links" do
    stub_order_upstream(:get, "/orders", "index.json")

    get "/en/example_orders/orders?per_page=25&sort=number&direction=desc", headers: headers

    data = page_body.dig("props", "data")
    expect(data["nextHref"]).to include("per_page=25")
    expect(data["nextHref"]).to include("sort=number")
    expect(data["filterHrefs"].first["href"]).to include("per_page=25")
  end

  it "does not offer edit to a read-only viewer" do
    stub_order_upstream(:get, "/orders/order-1", "show.json")
    read_only = auth_headers(grants: [ "example_orders:order:read" ])

    get "/en/example_orders/orders/order-1", headers: read_only

    expect(response).to have_http_status(:ok)
    expect(page_body.dig("props", "can", "order.update", "allowed")).to be(false)
  end

  it "creates an order with the idempotency claim" do
    get "/en/example_orders/orders/new", headers: headers
    token = page_body.dig("props", "meta", "formToken")
    stub_order_upstream(:post, "/orders", "create.json", status: 201)

    post "/en/example_orders/orders",
         params: { customerName: "Ada", status: "open", token: token },
         headers: headers

    expect(response).to have_http_status(:see_other)
    expect(response.location).to end_with("/en/example_orders/orders/order-101")
    expect(Rafelo::Core::IdempotencyKey.count).to eq(1)
  end

  it "redirects a conflict back to edit with a base error" do
    stub_order_upstream(:get, "/orders/order-1", "show.json")
    get "/en/example_orders/orders/order-1/edit", headers: headers
    token = page_body.dig("props", "meta", "formToken")
    version = page_body.dig("props", "data", "order", "version")
    stub_order_upstream(:patch, "/orders/order-1", "conflict.json", status: 409)

    patch "/en/example_orders/orders/order-1",
          params: { customerName: "Ada", status: "paid", version: version, token: token },
          headers: headers

    expect(response).to have_http_status(:see_other)
    follow_redirect(headers.fetch("Cookie"))
    expect(page_body.dig("props", "errors", "base")).to eq("The order changed since you opened it.")
  end

  it "enqueues the export job once for the viewer" do
    ActiveJob::Base.queue_adapter.enqueued_jobs.clear
    stub_order_upstream(:get, "/orders", "index.json")
    get "/en/example_orders/orders", headers: headers
    token = page_body.dig("props", "meta", "formToken")

    post "/en/example_orders/orders/export", params: { token: token }, headers: headers
    expect(response).to have_http_status(:see_other)
    post "/en/example_orders/orders/export", params: { token: token }, headers: headers

    expect(response).to have_http_status(:see_other)
    expect(Rafelo::Core::Export.where(viewer_id: "7").count).to eq(1)
    expect(ActiveJob::Base.queue_adapter.enqueued_jobs.map { |job| job[:job] })
      .to include(Rafelo::ExampleOrders::OrderExportJob)
  ensure
    ActiveJob::Base.queue_adapter.enqueued_jobs.clear
  end
end
