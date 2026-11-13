require "rails_helper"

RSpec.describe Rafelo::Core::AuditRecorder do
  after { Rafelo::Core::Current.reset }

  it "truncates IPv4 and IPv6 and maps unknown user agents to other" do
    expect(described_class.truncate_ip("203.0.113.77")).to eq("203.0.113.0/24")
    expect(described_class.truncate_ip("::ffff:203.0.113.77")).to eq("203.0.113.0/24")
    expect(described_class.truncate_ip("2001:db8:1234:5678::1")).to eq("2001:db8:1234::/48")
    expect(described_class.truncate_ip("not-an-ip")).to be_nil
    expect(described_class.family("")).to eq("other")
    expect(described_class.family("x" * 600)).to eq("other")
    expect(described_class.family("Mozilla/5.0 Chrome/140.0")).to eq("chrome")
  end

  it "writes one row per request even when called twice" do
    request = double("request", request_id: "request-1", remote_ip: "203.0.113.7", user_agent: "Chrome/140.0", path: "/en")
    controller = double("controller", request: request)
    Rafelo::Core::Current.request_id = "request-1"
    Rafelo::Core::Current.trace_id = "trace-1"

    2.times do
      described_class.record(controller: controller, event: "write", outcome: "success", target: "/en/done")
    end

    expect(Rafelo::Core::AuditEvent.where(event: "write").count).to eq(1)
    expect(Rafelo::Core::AuditEvent.last.ip).to eq("203.0.113.0/24")
  end

  it "sets the marker only after the insert and does not swallow an insert failure" do
    request = double("request", request_id: "request-1", remote_ip: "203.0.113.7", user_agent: "Chrome/140.0", path: "/en")
    controller = double("controller", request: request)
    allow(Rafelo::Core::AuditEvent).to receive(:create!).and_raise(ActiveRecord::StatementInvalid, "audit down")

    expect do
      described_class.record(controller: controller, event: "write", outcome: "success", target: "/en/done")
    end.to raise_error(ActiveRecord::StatementInvalid)
    expect(Rafelo::Core::Current.audit_recorded).to be_falsey
  end

  it "records the audit format version" do
    request = double("request", request_id: "request-1", remote_ip: "203.0.113.7", user_agent: "Chrome/140.0", path: "/en")
    controller = double("controller", request: request)

    described_class.record(controller: controller, event: "write", outcome: "success", target: "/en/done")

    expect(Rafelo::Core::AuditEvent.last.format_version).to eq(Rafelo::Core::AuditEvent::FORMAT_VERSION)
  end

  it "makes audit rows append-only in the database" do
    event = Rafelo::Core::AuditEvent.create!(
      occurred_at: Time.current, event: "write", outcome: "success", created_at: Time.current
    )

    expect { event.update!(outcome: "failure") }.to raise_error(ActiveRecord::StatementInvalid, /append-only/)
    expect { event.destroy }.to raise_error(ActiveRecord::StatementInvalid, /append-only/)
  end
end
