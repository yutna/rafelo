require "rails_helper"

RSpec.describe Rafelo::Core::BaseController do
  it "pins the implemented callback chain" do
    callbacks = ApplicationController._process_action_callbacks
    symbols = ->(kind) do
      callbacks.select { |callback| callback.kind == kind && callback.filter.is_a?(Symbol) }.map(&:filter)
    end

    expect(symbols.call(:before)).to eq(
      [ :verify_authenticity_token, :set_response_headers, :assign_request_context, :share_trace, :underscore_param_keys ]
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
