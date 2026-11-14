require "rails_helper"
require "yaml"
require "open3"
require "active_support/encrypted_configuration"

RSpec.describe "Deployment profiles" do
  def load_deploy(path)
    YAML.safe_load_file(Rails.root.join(path), aliases: true)
  end

  def host_count(role)
    Array(role.is_a?(Hash) ? role["hosts"] : role).length
  end

  def env_keys
    File.readlines(Rails.root.join(".env.ci.production"), chomp: true)
      .reject { |line| line.empty? || line.start_with?("#") }
      .map { |line| line.split("=", 2).first }
  end

  def dummy_credentials
    ActiveSupport::EncryptedConfiguration.new(
      config_path: Rails.root.join("config/credentials/dummy.yml.enc").to_s,
      key_path: Rails.root.join("config/credentials/dummy.key").to_s,
      env_key: "RAILS_MASTER_KEY",
      raise_if_missing_key: true
    ).config
  end

  let(:single) { load_deploy("config/deploy.yml") }
  let(:multi) { load_deploy("config/deploy.multi.yml") }

  it "describes one single-host profile with PostgreSQL and Disk Active Storage" do
    expect(single.fetch("service")).to eq("rafelo")
    expect(single.fetch("image")).to eq("rafelo")
    expect(single.fetch("deploy_timeout")).to be >= 120
    expect(single.dig("boot", "limit")).to eq(1)
    expect(single.fetch("servers").keys).to eq([ "web" ])
    expect(host_count(single.dig("servers", "web"))).to eq(1)
    expect(single.fetch("asset_path")).to eq("/rails/public/vite")
    expect(single.dig("env", "secret")).to eq([ "RAILS_MASTER_KEY" ])
    expect(single.dig("env", "clear", "SOLID_QUEUE_IN_PUMA")).to be(true)
    expect(single.dig("env", "clear", "ACTIVE_STORAGE_SERVICE")).to eq("local")
    expect(Array(single["volumes"])).to include("rafelo_storage:/rails/storage")
  end

  it "pins the single-host PostgreSQL accessory to the Dev Container major and a digest" do
    image = single.dig("accessories", "db", "image")
    match = image.match(/\Apostgres:(\d+)\.\d+@sha256:[0-9a-f]{64}\z/)
    expect(match).not_to be_nil
    expect(match[1]).to eq("18")
    expect(File.read(Rails.root.join(".devcontainer/compose.yaml")))
      .to match(/image:\s+postgres:18\.6@sha256:[0-9a-f]{64}/)
  end

  it "backups use the pinned PostgreSQL 18 data directory" do
    runbook = File.read(Rails.root.join("docs/operations/backup-restore.md"))

    expect(runbook).to include("pg1-path=/var/lib/postgresql/18/docker")
    expect(single.dig("accessories", "db", "volumes").join(" ")).to include("/var/lib/postgresql")
  end

  it "commits the encrypted production credentials contract" do
    path = Rails.root.join("config/credentials/production.yml.enc")

    expect(path).to be_file
    expect(path.size).to be_positive
    expect(path.binread).not_to include("secret_key_base")
  end

  it "rebuilds the Dev Container image when a pinned input changes" do
    workflow = File.read(Rails.root.join(".github/workflows/devcontainer.yml"))

    %w[mise.toml package.json package-lock.json].each do |path|
      expect(workflow).to include(%(- "#{path}"))
    end
    expect(workflow).to include(%(- "!.devcontainer/image_digest"))
  end

  it "describes a multi-host profile on the same image and code with managed services" do
    expect(multi.fetch("service")).to eq(single.fetch("service"))
    expect(multi.fetch("image")).to eq(single.fetch("image"))
    expect(multi.fetch("deploy_timeout")).to eq(single.fetch("deploy_timeout"))
    expect(multi.fetch("asset_path")).to eq(single.fetch("asset_path"))
    expect(multi.dig("boot", "limit")).to eq(1)
    expect(host_count(multi.dig("servers", "web"))).to be > 1
    expect(multi.dig("servers", "job", "cmd")).to eq("bin/jobs")
    expect(host_count(multi.dig("servers", "job"))).to be >= 1
    expect(multi.dig("env", "secret")).to eq([ "RAILS_MASTER_KEY" ])
    expect(multi.dig("env", "clear", "ACTIVE_STORAGE_SERVICE")).to eq("amazon")
    expect(multi.dig("env", "clear")).not_to have_key("SOLID_QUEUE_IN_PUMA")
    expect(multi).not_to have_key("accessories")
    expect(multi).not_to have_key("volumes")
  end

  it "keeps every production environment key in each profile's clear values" do
    [ single, multi ].each do |deploy|
      expected = env_keys - [ "RAILS_MASTER_KEY" ]

      expect(deploy.dig("env", "clear").keys).to include(*expected)
    end
  end

  it "keeps production secrets in the dummy credentials contract" do
    credentials = dummy_credentials

    expect(credentials.dig(:active_record_encryption, :primary_key)).to be_present
    expect(credentials.dig(:active_record_encryption, :deterministic_key)).to be_present
    expect(credentials.dig(:active_record_encryption, :key_derivation_salt)).to be_present
    expect(credentials.dig(:database, :password)).to be_present
    expect(credentials.dig(:database, :migration_password)).to be_present
    expect(credentials.dig(:aws, :access_key_id)).to be_present
    expect(credentials.dig(:aws, :secret_access_key)).to be_present
  end

  it "prepares the database as the migration role before the web server starts" do
    entrypoint = File.read(Rails.root.join("bin/docker-entrypoint"))

    expect(entrypoint).to include('RAFELO_DATABASE_ROLE=migration ./bin/rails db:prepare')
    expect(entrypoint).to include('RAFELO_DATABASE_ROLE=migration ./bin/rails rafelo:audit:partitions')
    expect(entrypoint).to include('exec "${@}"')
    expect(File.read(Rails.root.join("config/puma.rb")))
      .to include('plugin :solid_queue if ENV["SOLID_QUEUE_IN_PUMA"]')
    expect(File.read(Rails.root.join("config/queue.yml")))
      .to include('processes: <%= ENV.fetch("JOB_CONCURRENCY", 1) %>')
  end

  it "runs Thruster in front of Puma in the one production image" do
    dockerfile = File.read(Rails.root.join("Dockerfile"))

    expect(dockerfile).to match(/^CMD \["\.\/bin\/thrust", "\.\/bin\/rails", "server"\]$/)
    expect(dockerfile).to match(/^EXPOSE 80$/)
  end

  it "passes the deploy preflight" do
    output, status = Open3.capture2e(Rails.root.join("script/ci/deploy_preflight").to_s, Rails.root.to_s)

    expect(status).to be_success, output
    expect(output).to include("deploy_preflight:")
  end

  it "keeps runtime code from writing host-local state outside request and job temp files" do
    runtime = Dir[
      Rails.root.join("app/**/*.rb"),
      Rails.root.join("lib/**/*.rb"),
      Rails.root.join("engines/*/app/**/*.rb"),
      Rails.root.join("engines/*/lib/**/*.rb")
    ].reject { |path| path.include?("/generators/") }

    writes = runtime.select do |path|
      File.read(path).match?(/\b(?:File\.(?:write|binwrite|open)|IO\.write|FileUtils\.(?:cp|mv|mkdir_p|rm))\b/)
    end

    expect(writes).to be_empty, "host-local writes: #{writes.map { |path| path.delete_prefix("#{Rails.root}/") }.join(", ")}"
  end
end
