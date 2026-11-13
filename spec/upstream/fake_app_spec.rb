require "rails_helper"
require Rails.root.join("engines/core/spec/fake_upstream_app")

RSpec.describe FakeUpstreamApp do
  it "serves a fixture from an engine by path" do
    status, _headers, body = described_class.call("PATH_INFO" => "/invoices/index.json")

    expect(status).to eq(200)
    expect(JSON.parse(body.first).dig("data", 0, "id")).to eq("inv_1")
  end

  it "returns 404 for an unknown path and a missing upstream" do
    expect(described_class.call("PATH_INFO" => "/missing.json").first).to eq(404)
    expect(described_class.call("PATH_INFO" => "/invoices/index.json", "rafelo.upstream" => "missing").first).to eq(404)
  end

  it "holds no module paths" do
    paths = Rails.root.glob("engines/*/spec/fixtures/upstream/api/**/*.json").map { |path| path.to_s }

    expect(paths).not_to be_empty
    expect(paths).to all(include("engines/core/spec/fixtures/upstream/api/"))
  end
end
