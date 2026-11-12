require "rails_helper"

RSpec.describe Rafelo::Core::LocaleMiddleware do
  let(:downstream) { ->(_env) { [ 200, { "Content-Type" => "text/plain" }, [ "ok" ] ] } }
  let(:middleware) { described_class.new(downstream) }

  def request(path, method: "GET")
    Rack::MockRequest.env_for(path, method: method)
  end

  it "sits after ActionDispatch::DebugExceptions" do
    stack = Rails.application.middleware.map { |middleware| middleware.klass }
    debug = stack.index(ActionDispatch::DebugExceptions)
    locale = stack.index(described_class)

    expect(locale).to be > debug
  end

  it "passes through each exempt path" do
    %w[/up /core/ready /rails/health /cable /.well-known/x /vite/x /vite-dev/x /vite-test/x /icon.svg].each do |path|
      status, = middleware.call(request(path))
      expect(status).to eq(200), "#{path} was not exempt"
    end
  end

  it "adds the default locale to an unprefixed path and keeps the path and query" do
    status, headers, = middleware.call(request("/nope?x=1"))

    expect(status).to eq(302)
    expect(headers["Location"]).to eq("/en/nope?x=1")
  end

  it "keeps the query when canonicalizing a trailing slash" do
    status, headers, = middleware.call(request("/th/?x=1"))

    expect(status).to eq(302)
    expect(headers["Location"]).to eq("/th?x=1")
  end

  it "returns 404 for an unavailable locale and a non-GET unprefixed path" do
    expect { middleware.call(request("/fr")) }.to raise_error(ActionController::RoutingError)
    expect { middleware.call(request("/nope", method: "POST")) }.to raise_error(ActionController::RoutingError)
  end
end
