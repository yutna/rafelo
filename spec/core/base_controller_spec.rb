require "rails_helper"

RSpec.describe Rafelo::Core::BaseController do
  it "pins the implemented callback chain" do
    callbacks = ApplicationController._process_action_callbacks
    symbols = ->(kind) do
      callbacks.select { |callback| callback.kind == kind && callback.filter.is_a?(Symbol) }.map(&:filter)
    end

    expect(symbols.call(:before)).to eq(
      [ :verify_authenticity_token, :load_session, :require_module_enabled, :set_response_headers, :assign_request_context, :share_trace, :underscore_param_keys ]
    )
    expect(symbols.call(:around)).to eq([ :with_locale ])
    expect(symbols.call(:after)).to eq([ :verify_same_origin_request, :verify_authorized ])
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
