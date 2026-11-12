require "rails_helper"
require "json_schemer"

RSpec.describe "Home page contract", type: :request do
  let(:shared) { JSON.parse(Rails.root.join("config/contracts/_shared.json").read) }
  let(:schema) { JSON.parse(Rails.root.join("config/contracts/pages/home/index.json").read) }
  let(:schemer) do
    JSONSchemer.schema(
      schema,
      ref_resolver: ->(uri) { uri.to_s.start_with?("https://rafelo.local/contracts/_shared.json") ? shared : nil }
    )
  end

  def props
    get "/en"
    page = JSON.parse(response.body[/<script data-page="app" type="application\/json">(.*?)<\/script>/m, 1])
    page.fetch("props")
  end

  it "validates the real props against the generated schema" do
    expect(schemer.validate(props).to_a).to be_empty
  end

  it "rejects an extra nested key" do
    invalid = props
    invalid["data"]["extra"] = "nope"

    expect(schemer.validate(invalid).to_a).not_to be_empty
  end
end
