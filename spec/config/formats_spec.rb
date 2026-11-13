require "rails_helper"

RSpec.describe "Persisted formats" do
  it "reads every fixture written by a release pull request" do
    folders = PersistedFormatsReader.folders
    expect(folders).not_to be_empty

    folders.each do |folder|
      reader = PersistedFormatsReader.new(folder)

      reader.sessions.each do |session, token|
        expect(Rafelo::Core::Session.find_by_token(token)).to eq(session)
        expect(session.format_version).to be_in(Rafelo::Core::Session::READABLE_FORMAT_VERSIONS)
        session.destroy
      end

      reader.idempotency_keys.each do |key|
        expect(Rafelo::Core::IdempotencyKey.readable_format).to include(key)
        expect(key.format_version).to be_in(Rafelo::Core::IdempotencyKey::READABLE_FORMAT_VERSIONS)
        key.destroy
      end

      reader.jobs.each do |job|
        expect(job.rafelo_trace_id).to be_present
      end
    end
  end

  it "loads the latest release folder through the current readers" do
    reader = PersistedFormatsReader.new(PersistedFormatsReader.latest)
    expect(reader.folder).to be_directory
    expect(reader.rows("sessions.json")).not_to be_empty
    expect(reader.rows("idempotency_keys.json")).not_to be_empty
    expect(reader.rows("jobs.json")).not_to be_empty
  end

  it "reads previous-release and current-release rows together" do
    reader = PersistedFormatsReader.new(PersistedFormatsReader.latest)

    previous_session, previous_token = reader.sessions.first
    current_session, current_token = Rafelo::Core::Session.start(
      viewer: Struct.new(:id, :name).new("fixture-current", "Fixture Current"),
      access_token: "fixture-current-access",
      refresh_token: "fixture-current-refresh",
      access_expires_at: 5.minutes.from_now,
      grants: [ "fixture:read" ]
    )

    ids = [ previous_session.id, current_session.id ]
    expect(Rafelo::Core::Session.readable_format.where(id: ids)).to contain_exactly(previous_session, current_session)
    expect(Rafelo::Core::Session.find_by_token(previous_token)).to eq(previous_session)
    expect(Rafelo::Core::Session.find_by_token(current_token)).to eq(current_session)

    previous_key = reader.idempotency_keys.first
    current_key = Rafelo::Core::IdempotencyKey.create!(
      format_version: Rafelo::Core::IdempotencyKey::FORMAT_VERSION,
      token_digest: Digest::SHA256.hexdigest("fixture-current-token"),
      viewer_id: "fixture-current",
      payload_digest: "fixture-payload",
      status: "pending",
      attempt: 1,
      claimed_at: Time.current,
      expires_at: 1.hour.from_now
    )

    key_ids = [ previous_key.id, current_key.id ]
    expect(Rafelo::Core::IdempotencyKey.readable_format.where(id: key_ids)).to contain_exactly(previous_key, current_key)

    previous_job = reader.jobs.first
    current_job = previous_job.class.deserialize(previous_job.serialize)
    expect(current_job.rafelo_trace_id).to be_present
  end

  it "refuses rows whose format version the current code does not read" do
    reader = PersistedFormatsReader.new(PersistedFormatsReader.latest)

    session, token = reader.sessions.first
    session.update_column(:format_version, 999)
    expect(Rafelo::Core::Session.find_by_token(token)).to be_nil
    expect(Rafelo::Core::Session.readable_format.where(id: session.id)).to be_empty

    key = reader.idempotency_keys.first
    key.update_column(:format_version, 999)
    expect(Rafelo::Core::IdempotencyKey.readable_format.where(id: key.id)).to be_empty
  end
end
