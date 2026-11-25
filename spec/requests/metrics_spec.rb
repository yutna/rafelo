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
    Rafelo::Core::Metrics.record_upstream("api", 0.25, gateway: "OrdersGateway")
    Rafelo::Core::Metrics.record_upstream_error("api", "upstream.timeout", gateway: "OrdersGateway")
    Rafelo::Core::Metrics.circuit_state("api", "OrdersGateway", "red")
    Rafelo::Core::Metrics.circuit_open("api", "OrdersGateway")
    Rafelo::Core::Metrics.bulkhead_refused("api")
    Rafelo::Core::Metrics.csp_report(directive: "script-src", blocked_origin: "https://evil.test")

    get "/core/metrics"
    body = response.body

    expect(body).to include('rafelo_errors_total{code="resource.conflict"} 1')
    expect(body).to include("rafelo_token_refreshes_total 1")
    expect(body).to include("rafelo_token_refresh_failures_total 1")
    expect(body).to include("rafelo_grants_dropped_total 2")
    expect(body).to include('rafelo_upstream_calls_total{upstream="api",gateway="OrdersGateway"} 1')
    expect(body).to include('rafelo_upstream_duration_seconds_sum{upstream="api",gateway="OrdersGateway"} 0.25')
    expect(body).to include('rafelo_upstream_errors_total{code="upstream.timeout",gateway="OrdersGateway",upstream="api"} 1')
    expect(body).to include('rafelo_circuit_state{upstream="api",gateway="OrdersGateway",state="red"} 1')
    expect(body).to include('rafelo_circuit_open_total{gateway="OrdersGateway",upstream="api"} 1')
    expect(body).to include('rafelo_bulkhead_refused_total{upstream="api"} 1')
    expect(body).to include('rafelo_csp_reports_total{blocked_origin="external",directive="script-src"} 1')
    expect(body).to include("rafelo_jobs_ready")
    expect(body).to include('rafelo_db_dead_tuple_ratio{table="core_sessions"}')

    label_names = body.scan(/(\w+)="/).flatten.uniq
    expect(label_names - %w[controller action status upstream gateway code job le host pid role state directive blocked_origin table]).to be_empty
  end

  it "publishes the process identity as an OPS-04 metric" do
    identity = Rafelo::Core::ProcessIdentity.to_h

    get "/core/metrics"

    expect(response.body).to include(
      %(rafelo_process_info{host="#{identity[:host]}",pid="#{identity[:pid]}",role="#{identity[:role]}"} 1)
    )
  end

  it "escapes backslashes and drops control characters from labels" do
    Rafelo::Core::Metrics.record_upstream("a\\b\r", 0.1)

    get "/core/metrics"

    expect(response.body).to include('upstream="a\\\\b"')
    expect(response.body).not_to include("\r")
  end

  it "refuses a scrape from the public network" do
    get "/core/metrics", env: { "REMOTE_ADDR" => "203.0.113.10" }

    expect(response).to have_http_status(:not_found)
    expect(response.body).to be_empty
  end

  it "answers a scrape from the internal network" do
    get "/core/metrics", env: { "REMOTE_ADDR" => "10.0.0.5" }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("rafelo_process_info")
  end

  it "ignores a forwarded address from an untrusted peer" do
    get "/core/metrics", env: { "REMOTE_ADDR" => "203.0.113.10", "HTTP_X_FORWARDED_FOR" => "10.0.0.5" }

    expect(response).to have_http_status(:not_found)
  end

  it "refuses a public client behind the trusted proxy" do
    get "/core/metrics", env: { "REMOTE_ADDR" => "127.0.0.1", "HTTP_X_FORWARDED_FOR" => "203.0.113.10" }

    expect(response).to have_http_status(:not_found)
  end

  it "answers an internal client behind the trusted proxy" do
    get "/core/metrics", env: { "REMOTE_ADDR" => "127.0.0.1", "HTTP_X_FORWARDED_FOR" => "10.0.0.5" }

    expect(response).to have_http_status(:ok)
  end

  it "fails closed when the forwarded address does not resolve to a client" do
    %w[10.0.0.0/8 unknown].each do |forwarded|
      get "/core/metrics", env: { "REMOTE_ADDR" => "127.0.0.1", "HTTP_X_FORWARDED_FOR" => forwarded }

      expect(response).to have_http_status(:not_found), forwarded
    end
  end

  it "throttles scrapes per IP" do
    12.times do
      get "/core/metrics"
      expect(response).to have_http_status(:ok)
    end

    get "/core/metrics"
    expect(response).to have_http_status(:too_many_requests)
  end
end
