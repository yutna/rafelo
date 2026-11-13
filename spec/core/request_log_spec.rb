require "rails_helper"

RSpec.describe Rafelo::Core::RequestLog do
  after { described_class.current = nil }

  it "counts one query under the query cache and ignores schema and transaction events" do
    log = described_class.new
    described_class.current = log

    ActiveRecord::Base.transaction do
      ActiveRecord::Base.cache do
        2.times { Rafelo::Core::AuditEvent.count }
      end
    end

    expect(log.sql_count).to eq(1)
  end

  it "counts every upstream call and its time per upstream" do
    log = described_class.new
    described_class.current = log

    2.times do
      ActiveSupport::Notifications.instrument("upstream.call", name: :api) do
        sleep 0.001
      end
    end
    ActiveSupport::Notifications.instrument("upstream.call", name: :reports)

    expect(log.upstream_calls).to eq("api" => 2, "reports" => 1)
    expect(log.upstream_time["api"]).to be_positive
    expect(log.upstream_time["reports"]).to be >= 0
  end

  it "keeps collectors isolated between execution contexts" do
    first = described_class.new
    described_class.current = first

    other = nil
    Thread.new { other = described_class.current }.join

    expect(other).to be_nil
  end
end
