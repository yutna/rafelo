require "rails_helper"

RSpec.describe "Server error reporting", type: :request do
  class ServerErrorProbe
    attr_reader :reports

    def initialize
      @reports = []
    end

    def report(report)
      @reports << report
    end
  end

  let(:trace_id) { "a" * 32 }
  let(:headers) do
    auth_headers.merge("X-Request-Id" => "request-error", "traceparent" => "00-#{trace_id}-#{'b' * 16}-01")
  end
  let(:probe) { ErrorProbe.new }
  let(:forwarded) { [] }

  before do
    allow(Rafelo::Core::ReportingService).to receive(:capture) do |_error, handled:, severity:, context:|
      forwarded << { handled: handled, severity: severity, context: context }
    end
    Rails.error.subscribe(probe)
  end
  after { Rails.error.unsubscribe(probe) }

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

  def context_for(index = 0)
    probe.reports.fetch(index).context.to_h.stringify_keys
  end

  def forwarded_context(index = 0)
    forwarded.fetch(index).fetch(:context).to_h.stringify_keys
  end

  it "reports a handled catalog error with the ids and release" do
    get "/en/dummy/widgets/not_found", headers: headers

    expect(probe.reports.length).to eq(1)
    report = probe.reports.first
    expect(report.handled).to be(true)
    expect(context_for).to include(
      "code" => "resource.not_found",
      "request_id" => "request-error",
      "trace_id" => trace_id,
      "release" => "#{Rafelo::Core::Release.version}:#{Rafelo::Core::AssetVersion.call}"
    )
    expect(context_for.keys).to include("code", "request_id", "trace_id", "release")
    expect(forwarded_context.keys).to contain_exactly("code", "request_id", "trace_id", "release")
  end

  it "reports an unhandled exception once" do
    post "/en/dummy/widgets/crash", headers: headers

    expect(probe.reports.length).to eq(1)
    expect(probe.reports.first.handled).to be(false)
    expect(context_for["code"]).to eq("unexpected")
    expect(context_for["trace_id"]).to eq(trace_id)
  end

  it "reports a router 404 from the exceptions app" do
    get "/en/does-not-exist", headers: headers

    expect(probe.reports.length).to eq(1)
    expect(context_for["code"]).to eq("resource.not_found")
    expect(context_for["request_id"]).to eq("request-error")
    expect(context_for["trace_id"]).to eq(trace_id)
  end

  it "never attaches parameters, props, headers or cookies" do
    get "/en/dummy/widgets/not_found?token=secret-param", headers: headers.merge("X-Secret" => "header-secret")

    serialized = forwarded.map { |entry| entry[:context].to_json }.join
    expect(serialized).not_to include("secret-param", "header-secret", "Cookie", "auth")
  end
end
