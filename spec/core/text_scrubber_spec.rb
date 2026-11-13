require "rails_helper"

RSpec.describe Rafelo::Core::TextScrubber do
  let(:jwt) { "eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiI3In0.signature" }
  let(:token) { "a" * 40 }

  it "removes every credential class" do
    {
      "Bearer credential" => [ "Authorization: Bearer abc.def-123", "Authorization: [FILTERED]" ],
      "JWT" => [ "token=#{jwt}", "token=[FILTERED]" ],
      "email" => [ "ada@example.test", "[FILTERED]" ],
      "base64url run" => [ "session=#{token}", "session=[FILTERED]" ]
    }.each do |label, (input, expected)|
      expect(described_class.call(input)).to eq(expected), label
    end
  end

  it "cuts after scrubbing" do
    expect(described_class.cut("word " * 400, 1_000).length).to eq(1_000)
    expect(described_class.cut("Bearer #{token} #{"word " * 400}", 1_000)).to start_with("[FILTERED]")
  end

  it "scrubs each field of a client report" do
    report = Rafelo::Core::ClientErrorReport.from(
      "message" => "mail ada@example.test and #{jwt}",
      "stack" => "Bearer #{token}",
      "page" => "orders/#{token}",
      "path" => "/en/orders/#{token}?token=#{token}",
      "release" => "not-a-release",
      "requestId" => "request-1",
      "traceId" => "a" * 32
    ).to_h

    expect(report.values_at("message", "stack", "page", "path")).to all(include("[FILTERED]"))
    expect(report["path"]).not_to include("token=")
    expect(report["release"]).to eq("unknown")
    expect(report["trace_id"]).to eq("a" * 32)
  end
end
