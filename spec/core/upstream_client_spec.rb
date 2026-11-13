require "rails_helper"

class UpstreamRefreshingTokenProvider
  attr_reader :refreshes

  def initialize
    @token = "old"
    @refreshes = 0
  end

  def token = @token
  def service? = false

  def refresh!
    @refreshes += 1
    @token = "new"
  end
end

RSpec.describe Rafelo::Core::UpstreamClient do
  let(:config) do
    Rafelo::Core::UpstreamConfig.new(
      base_url: "http://upstream.test",
      open_timeout: 1,
      read_timeout: 2,
      write_timeout: 2,
      max_concurrent_calls: 2,
      max_response_bytes: 100,
      retry_budget: 1.0,
      idempotency_keys: false,
      service_token_gateways: [],
      breaker: { failure_threshold: 100, cool_off: 1 }
    )
  end
  let(:token) { Struct.new(:token).new("secret") }

  let(:client) do
    described_class.new(name: :test_api, config: config, token_provider: token,
                        request_id: "request-1", trace_id: "a" * 32)
  end

  it "performs a GET with the identity and trace headers" do
    stub = stub_request(:get, "http://upstream.test/invoices")
           .with(headers: {
             "Authorization" => "Bearer secret",
             "X-Request-Id" => "request-1",
             "traceparent" => /\A00-#{'a' * 32}-[0-9a-f]{16}-00\z/
           })
           .to_return(status: 200, body: '{"ok":true}')

    response = client.get("invoices")

    expect(response.body).to eq('{"ok":true}')
    expect(stub).to have_been_requested.once
  end

  it "passes only the incoming sampled bit and a fresh parent id" do
    sampled = described_class.new(
      name: :sampled, config: config, token_provider: token,
      request_id: "request-1", trace_id: "a" * 32, trace_sampled: true
    )
    parents = []
    stub_request(:get, "http://upstream.test/invoices")
      .with { |request| parents << request.headers["Traceparent"]; true }
      .to_return(status: 200, body: "{}")

    2.times { sampled.get("invoices") }

    expect(parents.length).to eq(2)
    expect(parents).to all(match(/\A00-#{'a' * 32}-[0-9a-f]{16}-01\z/))
    expect(parents.uniq.length).to eq(2)
  end

  it "sends no traceparent for an invalid trace id" do
    invalid = described_class.new(
      name: :invalid_trace, config: config, token_provider: token,
      request_id: "request-1", trace_id: "trace-1"
    )
    stub_request(:get, "http://upstream.test/invoices")
      .with { |request| !request.headers.key?("Traceparent") }
      .to_return(status: 200, body: "{}")

    expect(invalid.get("invoices").status).to eq(200)
  end

  it "rejects unsafe paths before any call" do
    [ "/invoices", "http://evil.test/steal", "invoices?x=1", "invoices\\x", "invoices#frag" ].each do |path|
      expect { client.get(path) }.to raise_error(ArgumentError)
    end
    [ "a/../b", "a//b", "a/./b", "" ].each do |path|
      expect { client.get(path) }.to raise_error(Rafelo::Core::ApplicationError)
    end
    [ "a/%2e%2e/b", "a%2f..%2fb", "a%5c..%5cb", "a%00b" ].each do |path|
      expect { client.get(path) }.to raise_error(Rafelo::Core::ApplicationError) { |error| expect(error.code).to eq("resource.not_found") }
    end
    [ "a\u0000b", "a\tb" ].each do |path|
      expect { client.get(path) }.to raise_error(ArgumentError)
    end
    expect(a_request(:get, /evil/)).not_to have_been_made
  end

  it "keeps the configured base path" do
    base = config.with(base_url: "http://upstream.test/base")
    path_client = described_class.new(name: :base, config: base, token_provider: token)
    stub = stub_request(:get, "http://upstream.test/base/invoices").to_return(status: 200, body: "{}")

    path_client.get("invoices")

    expect(stub).to have_been_requested.once
  end

  it "does not open the breaker on 4xx answers" do
    short = config.with(breaker: { failure_threshold: 1, cool_off: 60 })
    breaker_client = described_class.new(name: :four_xx, config: short, token_provider: token)
    stub_request(:get, "http://upstream.test/missing").to_return(status: 404, body: "{}")

    2.times do
      expect { breaker_client.get("missing") }.to raise_error(Rafelo::Core::ApplicationError) { |error| expect(error.code).to eq("resource.not_found") }
    end
  end

  it "refuses an upstream call inside a database transaction" do
    stub_request(:get, "http://upstream.test/invoices").to_return(status: 200, body: "{}")

    expect do
      ActiveRecord::Base.transaction { client.get("invoices") }
    end.to raise_error(Rafelo::Core::ApplicationError, /transaction/)
    expect(a_request(:get, "http://upstream.test/invoices")).not_to have_been_made
  end

  it "does not retry a 429 whose Retry-After cannot fit in the deadline" do
    short = config.with(retry_budget: 1.0)
    deadline_client = described_class.new(
      name: :deadline, config: short, token_provider: token, deadline: Rafelo::Core::RequestDeadline.new(0.05)
    )
    stub = stub_request(:get, "http://upstream.test/throttled")
           .to_return(status: 429, headers: { "Retry-After" => "60" }, body: "{}")

    expect { deadline_client.get("throttled") }.to raise_error(Rafelo::Core::ApplicationError)
    expect(stub).to have_been_requested.once
  end

  it "accepts HEAD and 304 responses that carry a Content-Length" do
    stub_request(:head, "http://upstream.test/head")
      .to_return(status: 200, headers: { "Content-Length" => "100" })
    stub_request(:get, "http://upstream.test/not-modified")
      .to_return(status: 304, headers: { "Content-Length" => "100" })
    stub_request(:get, "http://upstream.test/gzip")
      .to_return(status: 200, body: "compressed", headers: { "Content-Length" => "100", "Content-Encoding" => "gzip" })

    expect(client.head("head").status).to eq(200)
    expect(client.get("not-modified").status).to eq(304)
    expect(client.get("gzip").body).to eq("compressed")
  end

  it "treats a truncated response as unavailable" do
    stub_request(:get, "http://upstream.test/truncated")
      .to_return(status: 200, body: "x" * 10, headers: { "Content-Length" => "100" })

    expect { client.get("truncated") }.to raise_error(Rafelo::Core::ApplicationError) { |error| expect(error.code).to eq("upstream.unavailable") }
  end

  it "refuses a gateway-supplied identity header" do
    expect { client.get("invoices", headers: { "Authorization" => "other" }) }
      .to raise_error(ArgumentError, /may not set/)
  end

  it "maps each upstream status to its catalog code" do
    {
      401 => "auth.expired",
      403 => "auth.forbidden",
      404 => "resource.not_found",
      409 => "resource.conflict",
      413 => "unexpected",
      422 => "validation.failed",
      429 => "upstream.unavailable",
      500 => "upstream.unavailable",
      400 => "unexpected",
      304 => nil,
      410 => "resource.not_found",
      412 => "resource.conflict",
      413 => "unexpected",
      302 => "unexpected"
    }.each do |status, code|
      stub_request(:get, "http://upstream.test/status").to_return(status: status, body: "{}")
      if code.nil?
        expect(client.get("status").status).to eq(304)
      else
        expect { client.get("status") }.to raise_error(Rafelo::Core::ApplicationError) { |error| expect(error.code).to eq(code) }
      end
    end
  end

  it "refreshes once and resends a GET after a 401" do
    refreshing = UpstreamRefreshingTokenProvider.new
    old = stub_request(:get, "http://upstream.test/invoices")
      .with(headers: { "Authorization" => "Bearer old" })
      .to_return(status: 401, body: "{}")
    fresh = stub_request(:get, "http://upstream.test/invoices")
      .with(headers: { "Authorization" => "Bearer new" })
      .to_return(status: 200, body: '{"ok":true}')
    refreshing_client = described_class.new(name: :refresh, config: config, token_provider: refreshing)

    expect(refreshing_client.get("invoices").body).to eq('{"ok":true}')
    expect(refreshing.refreshes).to eq(1)
    expect(old).to have_been_requested.once
    expect(fresh).to have_been_requested.once
  end

  it "resends a keyless POST once after a 401" do
    refreshing = UpstreamRefreshingTokenProvider.new
    old = stub_request(:post, "http://upstream.test/invoices")
      .with(headers: { "Authorization" => "Bearer old" })
      .to_return(status: 401, body: "{}")
    fresh = stub_request(:post, "http://upstream.test/invoices")
      .with(headers: { "Authorization" => "Bearer new" })
      .to_return(status: 201, body: "{}")
    refreshing_client = described_class.new(name: :refresh_post, config: config, token_provider: refreshing)

    expect(refreshing_client.post("invoices", body: "{}").status).to eq(201)
    expect(refreshing.refreshes).to eq(1)
    expect(old).to have_been_requested.once
    expect(fresh).to have_been_requested.once
  end

  it "counts the resend separately from the page budget" do
    refreshing = UpstreamRefreshingTokenProvider.new
    budget = Rafelo::Core::CallBudget.new(refresh_budget: 1)
    stub_request(:get, "http://upstream.test/invoices")
      .to_return({ status: 401, body: "{}" }, { status: 200, body: "{}" })
    refreshing_client = described_class.new(
      name: :refresh_budget, config: config, token_provider: refreshing, budget: budget
    )

    expect(refreshing_client.get("invoices").status).to eq(200)
    expect(budget.count(:refresh_budget)).to eq(1)
  end

  it "instruments the resend with its own kind" do
    refreshing = UpstreamRefreshingTokenProvider.new
    kinds = []
    subscriber = ActiveSupport::Notifications.subscribe("upstream.call") { |*, payload| kinds << payload[:kind] }
    stub_request(:get, "http://upstream.test/invoices")
      .to_return({ status: 401, body: "{}" }, { status: 200, body: "{}" })
    refreshing_client = described_class.new(name: :refresh_kind, config: config, token_provider: refreshing)

    refreshing_client.get("invoices")

    expect(kinds).to eq([ :page, :session_resend ])
  ensure
    ActiveSupport::Notifications.unsubscribe(subscriber) if subscriber
  end

  it "retries a GET once on a 503" do
    stub_request(:get, "http://upstream.test/retry")
      .to_return({ status: 503, body: "{}" }, { status: 200, body: '{"ok":true}' })

    expect(client.get("retry").body).to eq('{"ok":true}')
  end

  it "does not retry a 503 when the retry budget is exhausted" do
    no_budget = config.with(retry_budget: 0.1)
    budget_client = described_class.new(name: :no_budget, config: no_budget, token_provider: token)
    stub = stub_request(:get, "http://upstream.test/budget").to_return(status: 503, body: "{}")

    expect { budget_client.get("budget") }.to raise_error(Rafelo::Core::ApplicationError)
    expect(stub).to have_been_requested.once
  end

  it "refuses a response over the byte cap" do
    stub_request(:get, "http://upstream.test/large").to_return(status: 200, body: "x" * 101)

    expect { client.get("large") }.to raise_error(Rafelo::Core::ApplicationError) do |error|
      expect(error.code).to eq("unexpected")
      expect(error.message).not_to include("x" * 20)
    end
  end

  it "opens the breaker after repeated failures" do
    short = config.with(breaker: { failure_threshold: 1, cool_off: 60 })
    breaker_client = described_class.new(name: :breaker, config: short, token_provider: token)
    stub_request(:get, "http://upstream.test/fail").to_return(status: 500, body: "{}")

    expect { breaker_client.get("fail") }.to raise_error(Rafelo::Core::ApplicationError)
    expect { breaker_client.get("fail") }.to raise_error(Rafelo::Core::ApplicationError) { |error| expect(error.code).to eq("upstream.circuit_open") }
  end
  it "marks the viewer's grants stale when the upstream answers 403" do
    viewer = Struct.new(:id, :name).new(7, "Ada")
    session, = Rafelo::Core::Session.start(
      viewer: viewer, access_token: "access", refresh_token: "refresh",
      access_expires_at: 5.minutes.from_now, grants: [ "billing:invoice:read" ]
    )
    Rafelo::Core::Current.session = session
    stub_request(:get, "http://upstream.test/invoices").to_return(status: 403, body: "{}")

    expect { client.get("invoices") }.to raise_error(Rafelo::Core::ApplicationError) { |error| expect(error.code).to eq("auth.forbidden") }

    session.reload
    expect(session.grants_generation).to eq(1)
    expect(session.grants_stale?).to be(true)
  ensure
    Rafelo::Core::Current.reset
  end
  it "sends Idempotency-Key only to an upstream that declares idempotency keys" do
    plain = stub_request(:post, "http://upstream.test/invoices")
      .with { |request| !request.headers.key?("Idempotency-Key") }
      .to_return(status: 201, body: "{}")
    keyed = stub_request(:post, "http://upstream.test/keyed")
      .with(headers: { "Idempotency-Key" => "key-1" })
      .to_return(status: 201, body: "{}")
    keyed_config = config.with(idempotency_keys: true)
    keyed_client = described_class.new(name: :keyed, config: keyed_config, token_provider: token)

    client.post("invoices", body: "{}", idempotency_key: "key-1")
    keyed_client.post("keyed", body: "{}", idempotency_key: "key-1")

    expect(plain).to have_been_requested.once
    expect(keyed).to have_been_requested.once
  end
  it "maps an upstream 413 to the error page rather than a form validation" do
    stub_request(:post, "http://upstream.test/invoices").to_return(status: 413, body: "{}")

    expect { client.post("invoices", body: "{}") }.to raise_error(Rafelo::Core::ApplicationError) { |error| expect(error.code).to eq("unexpected") }
  end
end
