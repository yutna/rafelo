require "rails_helper"

RSpec.describe Rafelo::Core::BaseController do
  it "declares the request callbacks in the expected order" do
    callbacks = ApplicationController._process_action_callbacks
    before = callbacks.select { |callback| callback.kind == :before }.map(&:filter)
    around = callbacks.select { |callback| callback.kind == :around }.map(&:filter)
    after = callbacks.select { |callback| callback.kind == :after }.map(&:filter)

    expect(before.index(:set_response_headers)).to be < before.index(:assign_request_context)
    expect(before.index(:assign_request_context)).to be < before.index(:underscore_param_keys)
    expect(around).to include(:with_locale)
    expect(after.last).to eq(:verify_authorized)
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
