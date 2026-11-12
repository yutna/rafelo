require "rails_helper"

RSpec.describe Rafelo::Core::BaseController do
  it "declares the request callbacks in the expected order" do
    callbacks = ApplicationController._process_action_callbacks.map(&:filter)

    expect(callbacks.index(:set_response_headers)).to be < callbacks.index(:assign_request_context)
    expect(callbacks.index(:assign_request_context)).to be < callbacks.index(:underscore_param_keys)
    expect(callbacks).to include(:with_locale)
    expect(callbacks).to include(:verify_authorized)
  end

  it "builds a page context through the factory" do
    context = Rafelo::Core::PageContextFactory.build(
      session: nil,
      flags: { search: true },
      locale: :en,
      request_id: "request-1",
      urls: nil
    )

    expect(context.locale).to eq(:en)
    expect(context.flags).to eq(search: true)
  end
end
