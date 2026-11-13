require "rails_helper"

RSpec.describe Rafelo::Core::ProductionRoutes do
  def route(path, verb: "GET", app: nil, defaults: {})
    double(
      path: double(spec: double(to_s: path)),
      verb: verb,
      app: app,
      defaults: defaults
    )
  end

  it "never descends into a mounted engine that the registry does not own" do
    fake = Class.new do
      def self.name = "Fake::Engine"
      def self.root = Pathname.new("/tmp/fake")
      def self.routes = raise("the walker must not descend")
      def self.call(_env) = [ 200, {}, [] ]
    end

    walked = described_class.walk(double(routes: [ route("/fake", verb: "", app: fake) ]), known_engines: [])

    expect(walked.length).to eq(1)
    expect(walked.first.kind).to eq("unknown")
    expect(walked.first.to).to eq("Fake::Engine")
  end

  it "normalizes a legacy path to the locale-level redirect shape" do
    engine = double(routes: double(routes: []))
    entry = double(path: "/orders", engine: engine, legacy_paths: { "/invoicing" => "/orders" })

    walked = described_class.module_routes([ entry ])

    expect(walked.first.path).to eq("/:locale/invoicing(/*rest)")
    expect(walked.first.kind).to eq("legacy_redirect")
  end

  it "walks a real locale-scoped LegacyRedirect with the same legacy shape" do
    entry = Rafelo::Core::Modules::Entry.new(
      key: :orders,
      engine: Object,
      path: "/orders",
      permission_prefixes: [ "orders" ],
      legacy_paths: { "/invoicing" => "/orders" },
      nav: {},
      flag: nil
    )
    routes = ActionDispatch::Routing::RouteSet.new
    routes.draw do
      scope ":locale", locale: /[a-z]{2}/ do
        get "/invoicing(/*rest)", to: Rafelo::Core::LegacyRedirect.new(entry, "/orders")
      end
    end

    walked = described_class.walk(routes)

    expect(walked.first.path).to eq("/:locale/invoicing(/*rest)")
    expect(walked.first.kind).to eq("legacy_redirect")
  end

  it "rejects an allow-listed route whose kind cannot be classified" do
    route = described_class::Route.new(verb: "GET|POST", path: "/both", to: "home#show", kind: "unknown")

    errors = described_class.check(walked: [ route ], allow_list: [ route ], module_routes: [])

    expect(errors).to include(a_string_matching(/unclassified: GET\|POST/))
  end

  it "allows the known ActionCable mount but not an unregistered mount" do
    cable = described_class::Route.new(verb: "", path: "/cable", to: "ActionCable::Server::Base", kind: "mount")
    fake = described_class::Route.new(verb: "", path: "/fake", to: "Fake::Engine", kind: "mount")

    expect(described_class.check(walked: [ cable ], allow_list: [ cable ], module_routes: [])).to be_empty
    expect(described_class.check(walked: [ fake ], allow_list: [ fake ], module_routes: [])).not_to be_empty
  end
end
