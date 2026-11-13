require "rails_helper"

require Rails.root.join("engines/core/spec/dummy_engine/lib/dummy_engine")

RSpec.describe "Module gating", type: :request do
  def dark_entry
    Rafelo::Core::Modules::Entry.new(
      key: :dummy,
      engine: DummyEngine::Engine,
      path: "/dummy",
      permission_prefixes: [ "dummy" ],
      legacy_paths: {},
      nav: {},
      flag: :dummy_flag
    )
  end

  before do
    allow(Rafelo::Core::Modules).to receive(:all).and_return([ dark_entry ])
    allow(Rafelo::Core::Flags).to receive(:enabled?).and_call_original
  end

  it "returns 404 for a dark module route inside a mounted engine" do
    allow(Rafelo::Core::Flags).to receive(:enabled?).with(:dummy_flag).and_return(false)

    get "/en/dummy/widgets"

    expect(response).to have_http_status(:not_found)
  end

  it "serves the route when the module flag is on" do
    allow(Rafelo::Core::Flags).to receive(:enabled?).with(:dummy_flag).and_return(true)

    get "/en/dummy/widgets"

    expect(response).to have_http_status(:ok)
  end
end
