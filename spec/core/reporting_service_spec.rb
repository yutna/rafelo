require "rails_helper"

RSpec.describe Rafelo::Core::ReportingService do
  it "logs only the allow-listed context fields" do
    lines = []
    allow(Rails.logger).to receive(:info) { |line| lines << JSON.parse(line) }

    described_class.capture(
      RuntimeError.new("boom"),
      handled: false,
      severity: :error,
      context: {
        code: "unexpected",
        host: "app-1",
        pid: 42,
        role: "web",
        partition: "core_audit_events_default",
        database_role: "acme_runtime",
        rows: 2,
        message: "boom",
        secret: "must not be logged"
      }
    )

    context = lines.fetch(0).fetch("context")
    expect(context.keys).to contain_exactly(
      "code", "host", "pid", "role", "partition", "database_role", "rows", "message"
    )
    expect(context["secret"]).to be_nil
  end
end
