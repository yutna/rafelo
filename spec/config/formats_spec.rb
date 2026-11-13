require "rails_helper"
require "json"

RSpec.describe "Persisted formats" do
  it "reads every fixture written by a release pull request" do
    folders = Rails.root.glob("spec/fixtures/formats/v*")
    expect(folders).not_to be_empty

    folders.each do |folder|
      JSON.parse(folder.join("sessions.json").read).each do |attributes|
        token = attributes.delete("token")
        session = Rafelo::Core::Session.create!(attributes)
        expect(Rafelo::Core::Session.find_by_token(token)).to eq(session)
        expect(session.format_version).to be_in(Rafelo::Core::Session::READABLE_FORMAT_VERSIONS)
        session.destroy
      end

      JSON.parse(folder.join("idempotency_keys.json").read).each do |attributes|
        key = Rafelo::Core::IdempotencyKey.create!(attributes)
        expect(key.format_version).to be_in(Rafelo::Core::IdempotencyKey::READABLE_FORMAT_VERSIONS)
        key.destroy
      end

      JSON.parse(folder.join("jobs.json").read).each do |data|
        job = data["job_class"].constantize.deserialize(data)
        expect(job.rafelo_trace_id).to be_present
        expect(job.rafelo_request_id).to eq(data["rafelo_request_id"])
      end
    end
  end
end
