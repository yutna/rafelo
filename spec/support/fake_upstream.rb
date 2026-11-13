# frozen_string_literal: true

module FakeUpstream
  FIXTURE_ROOT = Rails.root.join("engines", "core", "spec", "fixtures", "upstream", "api")

  def fixture_body(path)
    FIXTURE_ROOT.join(path).read
  end

  def stub_upstream(method, path, fixture:, status: 200, base_url: "http://upstream.test")
    stub_request(method, "#{base_url}#{path}")
      .to_return(status: status, body: fixture_body(fixture), headers: { "Content-Type" => "application/json" })
  end
end

RSpec.configure do |config|
  config.include FakeUpstream
end
