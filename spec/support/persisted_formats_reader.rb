# frozen_string_literal: true

require "json"

# Reads a persisted-format fixture folder through the current readers. The
# folder is written by `bin/rails formats:dump` in a release pull request
# (SEC-16); the reader refuses a row whose format version the current code
# does not accept instead of creating it blindly.
class PersistedFormatsReader
  class UnsupportedVersion < StandardError; end

  attr_reader :folder

  def initialize(folder)
    @folder = Pathname(folder)
  end

  def self.root
    Rails.root.join("spec/fixtures/formats")
  end

  def self.folders
    root.glob("v*").select(&:directory?).sort_by { |path| version_of(path) }
  end

  def self.latest
    folders.last
  end

  def self.version_of(path)
    Gem::Version.new(path.basename.to_s.delete_prefix("v"))
  end

  def sessions
    rows("sessions.json").map do |attributes|
      ensure_readable!(Rafelo::Core::Session, attributes)
      token = attributes.fetch("token")
      [ Rafelo::Core::Session.create!(attributes.except("id", "token")), token ]
    end
  end

  def idempotency_keys
    rows("idempotency_keys.json").map do |attributes|
      ensure_readable!(Rafelo::Core::IdempotencyKey, attributes)
      Rafelo::Core::IdempotencyKey.create!(attributes)
    end
  end

  def jobs
    rows("jobs.json").map do |data|
      data.fetch("job_class").constantize.deserialize(data)
    end
  end

  def rows(name)
    JSON.parse(folder.join(name).read)
  end

  private

  def ensure_readable!(model, attributes)
    version = Integer(attributes.fetch("format_version"))
    return if model::READABLE_FORMAT_VERSIONS.include?(version)

    raise UnsupportedVersion, "#{model.name} format #{version} is not readable"
  end
end
