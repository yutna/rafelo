require "rails_helper"
require "yaml"

RSpec.describe Rafelo::Core::Export do
  it "purges expired rows and their files in batches" do
    expired = described_class.create!(viewer_id: "7", status: "ready", filename: "old.csv", expires_at: 1.hour.ago)
    expired.file.attach(io: StringIO.new("old"), filename: "old.csv")
    live = described_class.create!(viewer_id: "7", status: "ready", filename: "new.csv", expires_at: 1.hour.from_now)
    live.file.attach(io: StringIO.new("new"), filename: "new.csv")

    described_class.purge_expired

    expect(described_class.exists?(expired.id)).to be(false)
    expect(described_class.exists?(live.id)).to be(true)
  end

  it "attaches a file and marks the row ready from a viewer job" do
    export = described_class.create!(viewer_id: "7", filename: "new.csv", expires_at: 1.hour.from_now)
    viewer = Struct.new(:id, :name).new(7, "Ada")
    session, = Rafelo::Core::Session.start(
      viewer: viewer, access_token: "a", refresh_token: "r", access_expires_at: 5.minutes.from_now
    )
    job_class = Class.new(Rafelo::Core::ExportJob) do
      def perform(session_id, export_id)
        with_viewer_session(session_id) do
          export = Rafelo::Core::Export.find(export_id)
          attach!(export, io: StringIO.new("content"), filename: "new.csv")
        end
      end
    end
    stub_const("ExportJobProbe", job_class)

    ExportJobProbe.perform_now(session.id, export.id)

    expect(export.reload.status).to eq("ready")
    expect(export.file).to be_attached
  end
  it "schedules the export sweep" do
    config = YAML.load_file(Rails.root.join("config/recurring.yml"), aliases: true)
    expect(config.dig("production", "export_sweep", "class")).to eq("Rafelo::Core::ExportSweepJob")
  end
end
