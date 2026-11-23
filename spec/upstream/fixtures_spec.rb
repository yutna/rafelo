require "rails_helper"

RSpec.describe "Upstream fixtures" do
  it "holds parseable synthetic responses for success and every error class" do
    files = Dir[Rails.root.join("engines/core/spec/fixtures/upstream/api/**/*.json")]

    expect(files).not_to be_empty
    files.each do |file|
      expect { JSON.parse(File.read(file)) }.not_to raise_error, file
    end
  end

  it "stubs a success response through the helper" do
    stub_upstream(:get, "/invoices", fixture: "invoices/index.json")

    response = Net::HTTP.get_response(URI("http://upstream.test/invoices"))

    expect(response.code).to eq("200")
    expect(JSON.parse(response.body).dig("data", 0, "id")).to eq("inv_1")
  end

  it "has a synthetic grant catalog for drift checks" do
    grants = JSON.parse(File.read(Rails.root.join("config/grants.json"))).fetch("grants")

    expect(grants).to include("billing:invoice:read")
  end

  it "keeps the previous fixture path as a one-release compatibility copy" do
    previous = Rails.root.join("engines/core/spec/fixtures/upstream/api/grants.json")
    current = Rails.root.join("config/grants.json")

    expect(previous).to exist
    previous_grants = JSON.parse(previous.read).fetch("grants")
    current_grants = JSON.parse(current.read).fetch("grants")
    expect(previous_grants - current_grants).to be_empty
  end
end
