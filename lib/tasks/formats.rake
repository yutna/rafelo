# frozen_string_literal: true

require "fileutils"
require "json"

namespace :formats do
  desc "Dump synthetic persisted-format fixtures for the current VERSION"
  task dump: :environment do
    version = File.read(Rails.root.join("VERSION")).strip
    root = Rails.root.join("spec/fixtures/formats", "v#{version}")
    FileUtils.mkdir_p(root)

    sessions = 2.times.map do |index|
      viewer = Struct.new(:id, :name).new("fixture-#{index + 1}", "Fixture #{index + 1}")
      session, token = Rafelo::Core::Session.start(
        viewer: viewer,
        access_token: "fixture-access-#{index + 1}",
        refresh_token: "fixture-refresh-#{index + 1}",
        access_expires_at: 5.minutes.from_now,
        grants: [ "fixture:read" ]
      )
      attributes = session.attributes.merge("token" => token)
      session.destroy
      attributes
    end
    File.write(root.join("sessions.json"), JSON.pretty_generate(sessions))

    keys = %w[pending succeeded failed unknown].map do |status|
      {
        "format_version" => Rafelo::Core::IdempotencyKey::FORMAT_VERSION,
        "token_digest" => Digest::SHA256.hexdigest("fixture-token-#{status}"),
        "viewer_id" => "fixture-1",
        "payload_digest" => "fixture-payload",
        "status" => status,
        "attempt" => 1,
        "outcome" => status == "succeeded" ? "/en/fixture" : nil,
        "claimed_at" => Time.current.iso8601(9),
        "expires_at" => 1.hour.from_now.iso8601(9)
      }
    end
    File.write(root.join("idempotency_keys.json"), JSON.pretty_generate(keys))

    Rails.application.eager_load!
    jobs = job_classes.map do |klass|
      data = klass.new.serialize
      data.merge("job_class" => klass.name)
    end
    File.write(root.join("jobs.json"), JSON.pretty_generate(jobs))

    prune!
    puts "formats: dumped #{sessions.length} sessions, #{keys.length} keys and #{jobs.length} jobs to #{root}"
  end

  desc "Check persisted-format fixtures for the current VERSION"
  task check: :environment do
    version = File.read(Rails.root.join("VERSION")).strip
    root = Rails.root.join("spec/fixtures/formats", "v#{version}")
    abort "formats: missing fixtures for v#{version} at #{root}" unless root.directory?

    folders = Rails.root.glob("spec/fixtures/formats/v*").select(&:directory?)
    abort "formats: keep at most three fixture folders (SEC-16)" if folders.length > 3

    sessions = read_json!(root.join("sessions.json"))
    abort "formats: sessions.json is empty" if sessions.empty?
    sessions.each do |attributes|
      token = attributes["token"]
      abort "formats: session fixture has no token" if token.blank?
      abort "formats: session token_digest does not match" unless attributes["token_digest"] == Rafelo::Core::Session.digest(token)
      ensure_readable!(Rafelo::Core::Session, attributes)
    end

    keys = read_json!(root.join("idempotency_keys.json"))
    abort "formats: idempotency_keys.json is empty" if keys.empty?
    keys.each do |attributes|
      ensure_readable!(Rafelo::Core::IdempotencyKey, attributes)
      abort "formats: unknown idempotency status" unless Rafelo::Core::IdempotencyKey::STATUSES.include?(attributes["status"])
    end

    jobs = read_json!(root.join("jobs.json"))
    abort "formats: jobs.json is empty" if jobs.empty?
    jobs.each do |data|
      klass = data["job_class"].to_s.constantize
      abort "formats: #{klass} is not an Active Job" unless klass <= ActiveJob::Base
      job = klass.deserialize(data)
      abort "formats: #{klass} lost its trace id" if job.rafelo_trace_id.blank?
      abort "formats: #{klass} lost its request id" unless job.rafelo_request_id == data["rafelo_request_id"]
    end

    missing = job_classes.map(&:name) - jobs.map { |data| data["job_class"] }
    abort "formats: missing job fixtures: #{missing.join(", ")}" if missing.any?

    puts "formats: ok for v#{version} (#{sessions.length} sessions, #{keys.length} keys, #{jobs.length} jobs)"
  end

  def read_json!(path)
    JSON.parse(path.read)
  rescue JSON::ParserError => error
    abort "formats: #{path.basename} is not valid JSON (#{error.message})"
  end

  def ensure_readable!(model, attributes)
    version = Integer(attributes["format_version"])
    return if model::READABLE_FORMAT_VERSIONS.include?(version)

    abort "formats: #{model.name} format #{version} is not readable"
  rescue ArgumentError, TypeError
    abort "formats: #{model.name} fixture has no readable format_version"
  end

  def job_classes
    roots = [ Rails.root.join("app/jobs") ] + Rails.root.glob("engines/*/app/jobs")
    roots.flat_map { |dir| dir.glob("**/*.rb") }.filter_map do |file|
      relative = file.to_s.split("/app/jobs/").last.sub(/\.rb\z/, "")
      klass = relative.camelize.constantize
      next unless klass <= ActiveJob::Base

      (klass.instance_method(:perform).owner == ActiveJob::Execution) ? nil : klass
    rescue NameError
      nil
    end.uniq
  end

  def prune!
    versions = Rails.root.glob("spec/fixtures/formats/v*").filter_map do |path|
      Gem::Version.new(File.basename(path).delete_prefix("v"))
    rescue ArgumentError
      nil
    end.sort
    keep = versions.last(3)
    versions.each do |version|
      next if keep.include?(version)

      FileUtils.rm_rf(Rails.root.join("spec/fixtures/formats", "v#{version}"))
    end
  end
end
