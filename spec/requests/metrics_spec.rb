require "rails_helper"

RSpec.describe "Metrics endpoint", type: :request do
  before { Rafelo::Core::Metrics.reset! }

  it "exposes the allow-listed series without viewer data" do
    get "/en", headers: auth_headers
    get "/core/metrics"

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("text/plain; version=0.0.4")
    body = response.body
    expect(body).to include('rafelo_requests_total{controller="HomeController",action="show",status="200"}')
    expect(body).to include("rafelo_request_duration_seconds_bucket")
    expect(body).to include("rafelo_db_pool_waiting")
    expect(body).not_to include("viewer")
    expect(body).not_to include("session_token")
    expect(body).not_to include("request_id")
  end

  it "records errors, refreshes, dropped grants and upstream calls without labels outside the allow-list" do
    Rafelo::Core::Metrics.record_error("resource.conflict")
    Rafelo::Core::Metrics.token_refresh(success: true)
    Rafelo::Core::Metrics.token_refresh(success: false)
    Rafelo::Core::Metrics.grants_dropped(2)
    Rafelo::Core::Metrics.record_upstream("api", 0.25)

    get "/core/metrics"
    body = response.body

    expect(body).to include('rafelo_errors_total{code="resource.conflict"} 1')
    expect(body).to include("rafelo_token_refreshes_total 1")
    expect(body).to include("rafelo_token_refresh_failures_total 1")
    expect(body).to include("rafelo_grants_dropped_total 2")
    expect(body).to include('rafelo_upstream_calls_total{upstream="api"} 1')
    expect(body).to include('rafelo_upstream_duration_seconds_sum{upstream="api"} 0.25')

    label_names = body.scan(/(\w+)="/).flatten.uniq
    expect(label_names - %w[controller action status upstream code job le]).to be_empty
  end
end
