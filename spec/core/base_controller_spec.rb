require "rails_helper"

RSpec.describe Rafelo::Core::BaseController do
  def callback_identity(callback)
    filter = callback.filter
    return "#{callback.kind}:#{filter}" if filter.is_a?(Symbol)

    path = filter.source_location&.first.to_s
    "#{callback.kind}:#{path.split('/lib/').last || File.basename(path)}"
  end

  def exempted_actions(controller, filter)
    callback = controller._process_action_callbacks.find { |item| item.filter == filter }
    return [] unless callback

    Array(callback.instance_variable_get(:@unless)).flat_map do |condition|
      next [] unless condition.instance_variable_get(:@conditional_key) == :only

      condition.instance_variable_get(:@actions).to_a
    end
  end

  it "pins the full resolved callback chain" do
    callbacks = ApplicationController._process_action_callbacks.map { |callback| callback_identity(callback) }

    expect(callbacks).to eq(
      [
        "before:verify_authenticity_token",
        "after:verify_same_origin_request",
        "around:action_text/engine.rb",
        "before:inertia_rails/controller.rb",
        "after:inertia_rails/controller.rb",
        "before:action_controller/metal/allow_browser.rb",
        "before:set_response_headers",
        "before:assign_request_context",
        "around:with_locale",
        "before:underscore_param_keys",
        "before:load_session",
        "before:require_module_enabled",
        "before:refresh_stale_grants",
        "before:require_viewer",
        "after:verify_authorized"
      ]
    )
  end

  it "lists every public endpoint that skips a core callback" do
    expect(exempted_actions(SessionsController, :load_session)).to contain_exactly("new", "create")
    expect(exempted_actions(SessionsController, :refresh_stale_grants)).to contain_exactly("new", "create")
    expect(exempted_actions(SessionsController, :require_viewer)).to contain_exactly("new", "create")
    expect(exempted_actions(Core::ClientErrorsController, :load_session)).to contain_exactly("create")
    expect(exempted_actions(Core::ClientErrorsController, :refresh_stale_grants)).to contain_exactly("create")
    expect(exempted_actions(Core::ClientErrorsController, :require_viewer)).to contain_exactly("create")
    expect(ComponentCatalogController._process_action_callbacks.map(&:filter)).not_to include(:verify_authorized)
    expect(Core::ClientErrorsController._process_action_callbacks.map(&:filter)).not_to include(:verify_authorized)
  end

  it "builds the page context with a Urls object for the request locale" do
    controller = ApplicationController.new
    context = I18n.with_locale(:th) { controller.page_context }

    expect(context.urls).to be_a(Rafelo::Core::Urls)
    expect(context.locale).to eq(:th)
  end

  it "returns 404 for a dark module route" do
    entry = Rafelo::Core::Modules::Entry.new(
      key: :secret, engine: ->(_env) { [ 200, {}, [ "ok" ] ] }, path: "/secret",
      permission_prefixes: [ "secret" ], legacy_paths: {}, nav: {}, flag: :secret_flag
    )
    allow(Rafelo::Core::Modules).to receive(:all).and_return([ entry ])
    allow(Rafelo::Core::Flags).to receive(:enabled?).with(:secret_flag).and_return(false)
    controller = ApplicationController.new
    allow(controller).to receive(:request).and_return(double(original_fullpath: "/en/secret/items"))

    expect { controller.send(:require_module_enabled) }.to raise_error(ActionController::RoutingError)
  end

  it "builds a gateway with the current token provider and budget" do
    Rafelo::Core::Current.token_provider = Struct.new(:token, :service?).new("secret", false)
    Rafelo::Core::Current.call_budget = Rafelo::Core::CallBudget.new(api: 2)
    gateway = ApplicationController.new.gateway(ExampleInvoicesGateway)

    expect(gateway.client).to be_a(Rafelo::Core::UpstreamClient)
    expect(gateway.budget.count(:api)).to eq(0)
  ensure
    Rafelo::Core::Current.token_provider = nil
    Rafelo::Core::Current.call_budget = nil
  end

  it "builds a page context through the factory" do
    urls = Rafelo::Core::Urls.new(locale: :en, router: double("router"))
    context = Rafelo::Core::PageContextFactory.build(
      session: nil,
      flags: { search: true },
      locale: :en,
      request_id: "request-1",
      urls: urls
    )

    expect(context.locale).to eq(:en)
    expect(context.flags).to eq(search: true)
    expect(context.urls).to be(urls)
  end
end
