require "rails_helper"
require "open3"

RSpec.describe "Production configuration" do
  SEAM = Rails.root.join("spec/config/production_credentials_seam.rb")

  DUMMY_ENV = {
    "RAILS_ENV" => "production",
    "RAILS_MASTER_KEY" => File.read(Rails.root.join("config/credentials/dummy.key")).strip,
    "RUBYOPT" => [ ENV["RUBYOPT"], "-r#{SEAM}" ].compact.join(" "),
    "RAILS_SEAM_GEMFILE" => Rails.root.join("Gemfile").to_s,
    "ACME_API_BASE_URL" => "http://localhost:4000",
    "RAILS_HOSTS" => "example.com",
    "DB_USER" => "acme_runtime",
    # Sentinels: a production secret read from one of these names shows up in
    # the boot below and fails the credential-source example (BE-08, SEC-07).
    "DB_PASSWORD" => "sentinel-env-db-password",
    "DB_MIGRATION_PASSWORD" => "sentinel-env-migration-password",
    "AWS_ACCESS_KEY_ID" => "sentinel-env-access-key",
    "AWS_SECRET_ACCESS_KEY" => "sentinel-env-secret-key",
    "ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY" => "sentinel-env-deterministic-key",
    "ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT" => "sentinel-env-key-derivation-salt",
    "SECRET_KEY_BASE" => "sentinel-env-secret-key-base"
  }.freeze

  SCRIPT = <<~'RUBY'
    require "rack/mock"
    app = Rails.application
    request = Rack::MockRequest.new(app)
    page = request.get("/en", "HTTP_HOST" => "example.com", "HTTPS" => "on")
    puts({
      hosts: app.config.hosts,
      require_master_key: app.config.require_master_key,
      runtime_role: app.config.x.database.runtime_role,
      force_ssl: app.config.force_ssl,
      assume_ssl: app.config.assume_ssl,
      excluded: app.config.host_authorization[:exclude].call(Struct.new(:path).new("/up")),
      unknown_host: request.get("/en", "HTTP_HOST" => "evil.test", "HTTPS" => "on").status,
      health: request.get("/up", "HTTP_HOST" => "example.com", "HTTPS" => "on").status,
      csp: page.headers["Content-Security-Policy"],
      csp_report_only: page.headers["Content-Security-Policy-Report-Only"],
      csp_report_only_setting: app.config.x.csp.report_only,
      devtools: InertiaRails::Devtools.enabled?,
      database_password: app.config.database_configuration.dig("production", "primary", "password"),
      migration_database_password: app.config.database_configuration.dig("production", "migration", "password"),
      credentials_database_password: Rails.application.credentials.dig(:database, :password),
      credentials_migration_password: Rails.application.credentials.dig(:database, :migration_password),
      secret_key_base: app.secret_key_base,
      credentials_secret_key_base: Rails.application.credentials.secret_key_base,
      encryption_primary_key: app.config.active_record.encryption.primary_key,
      credentials_encryption_primary_key: Rails.application.credentials.dig(:active_record_encryption, :primary_key),
      encryption_deterministic_key: app.config.active_record.encryption.deterministic_key,
      credentials_encryption_deterministic_key: Rails.application.credentials.dig(:active_record_encryption, :deterministic_key),
      encryption_key_derivation_salt: app.config.active_record.encryption.key_derivation_salt,
      credentials_encryption_key_derivation_salt: Rails.application.credentials.dig(:active_record_encryption, :key_derivation_salt),
      amazon_access_key_id: app.config.active_storage.service_configurations&.dig("amazon", "access_key_id"),
      amazon_secret_access_key: app.config.active_storage.service_configurations&.dig("amazon", "secret_access_key"),
      credentials_amazon_access_key_id: Rails.application.credentials.dig(:aws, :access_key_id),
      credentials_amazon_secret_access_key: Rails.application.credentials.dig(:aws, :secret_access_key)
    }.to_json)
  RUBY

  # The production boot reads every secret from the encrypted production
  # credentials. The specs point that path at the committed dummy credentials
  # with a RUBYOPT seam, encrypted with the committed dummy key, so they hold
  # no real secret and never write the tracked production file (BE-08, SEC-07).
  def production_config(env = {})
    output, error, status = Open3.capture3(DUMMY_ENV.merge(env), "bin/rails", "runner", SCRIPT, chdir: Rails.root.to_s)
    raise "production boot failed: #{error}" unless status.success?

    JSON.parse(output.lines.last)
  end

  it "forces SSL, allows only configured hosts, excludes /up and rejects an unknown host" do
    config = production_config

    expect(config["force_ssl"]).to be(true)
    expect(config["assume_ssl"]).to be(true)
    expect(config["require_master_key"]).to be(true)
    expect(config["hosts"]).to eq([ "example.com" ])
    expect(config["runtime_role"]).to eq("acme_runtime")
    expect(config["excluded"]).to be(true)
    expect(config["unknown_host"]).to eq(403)
    expect(config["health"]).to eq(200)
  end

  it "refuses to boot without a configured host instead of using example.com" do
    expect { production_config("RAILS_HOSTS" => nil, "RAILS_HOST" => nil) }
      .to raise_error(/production boot failed: .*RAILS_HOSTS or RAILS_HOST is required/m)
  end

  it "refuses to boot without DB_USER instead of skipping the audit grants" do
    expect { production_config("DB_USER" => nil) }
      .to raise_error(/production boot failed: .*DB_USER is required/m)
  end

  it "requires the amazon region and bucket instead of the old defaults" do
    expect { production_config("ACTIVE_STORAGE_SERVICE" => "amazon", "AWS_REGION" => "us-east-1") }
      .to raise_error(/production boot failed: .*AWS_BUCKET is required/m)
    expect { production_config("ACTIVE_STORAGE_SERVICE" => "amazon", "AWS_BUCKET" => "acme-production") }
      .to raise_error(/production boot failed: .*AWS_REGION is required/m)
  end

  it "boots the amazon profile with the dummy credentials" do
    config = production_config(
      "ACTIVE_STORAGE_SERVICE" => "amazon",
      "AWS_REGION" => "us-east-1",
      "AWS_BUCKET" => "acme-production"
    )

    expect(config["health"]).to eq(200)
  end

  it "fails closed when the amazon credentials are blank" do
    keys = %w[ACTIVE_STORAGE_SERVICE AWS_REGION AWS_BUCKET]
    previous = keys.to_h { |key| [ key, ENV[key] ] }
    ENV["ACTIVE_STORAGE_SERVICE"] = "amazon"
    ENV["AWS_REGION"] = "us-east-1"
    ENV["AWS_BUCKET"] = "acme-production"

    allow(Rails.application.credentials).to receive(:dig).with(:aws, :access_key_id).and_return(nil)
    allow(Rails.application.credentials).to receive(:dig).with(:aws, :secret_access_key).and_return(nil)
    storage = ERB.new(File.read(Rails.root.join("config/storage.yml")))
    expect { storage.result(binding) }
      .to raise_error(/aws.access_key_id is required when ACTIVE_STORAGE_SERVICE is amazon/)

    allow(Rails.application.credentials).to receive(:dig).with(:aws, :access_key_id).and_return("dummy")
    expect { ERB.new(File.read(Rails.root.join("config/storage.yml"))).result(binding) }
      .to raise_error(/aws.secret_access_key is required when ACTIVE_STORAGE_SERVICE is amazon/)
  ensure
    previous.each { |key, value| value.nil? ? ENV.delete(key) : ENV[key] = value }
  end

  it "never enables Inertia devtools in production, even when the env flag is set" do
    expect(production_config("INERTIA_DEVTOOLS_ENABLED" => "true")["devtools"]).to be(false)
    expect(File.read(Rails.root.join("config/production_routes.yml")))
      .not_to include("/_inertia/devtools")
  end

  it "enforces CSP by default and reports only when CSP_REPORT_ONLY is true" do
    enforced = production_config
    expect(enforced["csp"]).to be_present
    expect(enforced["csp_report_only"]).to be_nil
    expect(enforced["csp_report_only_setting"]).to be(false)

    report_only = production_config("CSP_REPORT_ONLY" => "true")
    expect(report_only["csp"]).to be_nil
    expect(report_only["csp_report_only"]).to be_present
    expect(report_only["csp_report_only_setting"]).to be(true)
  end

  it "refuses a malformed CSP_REPORT_ONLY instead of guessing" do
    expect { production_config("CSP_REPORT_ONLY" => "sometimes") }
      .to raise_error(/production boot failed: .*config\/core\.yml csp\.report_only .*must be true or false/m)
  end

  it "reads RAILS_HOST when RAILS_HOSTS is absent" do
    config = production_config("RAILS_HOSTS" => nil, "RAILS_HOST" => "app.example.test")

    expect(config["hosts"]).to eq([ "app.example.test" ])
  end

  # The exhaustive code check is Rafelo/EnvOnlyInConfig (enabled in
  # .rubocop.yml and canaried by script/ci/cops_canary): ENV and credentials
  # reads outside config/ fail the lint. The config files themselves are its
  # Exclude list, so this spec pins the three former production fallbacks.
  it "reads production secrets only from credentials, never the old ENV fallbacks" do
    expect(File.read(Rails.root.join("config/initializers/active_record_encryption.rb"))).not_to include("ENV[")
    expect(File.read(Rails.root.join("config/database.yml"))).not_to include('ENV["DB_PASSWORD"].presence')
    expect(File.read(Rails.root.join("config/database.yml"))).not_to include('ENV["DB_MIGRATION_PASSWORD"].presence')
    expect(File.read(Rails.root.join("config/storage.yml"))).not_to include('ENV["AWS_ACCESS_KEY_ID"]')
    expect(File.read(Rails.root.join("config/storage.yml"))).not_to include('ENV["AWS_SECRET_ACCESS_KEY"]')
    expect(File.read(Rails.root.join("config/environments/production.rb"))).not_to match(/^\s*config\.require_master_key\s*=/)
  end

  # The fallback strings above cannot see a new secret path; this example boots
  # with sentinel ENV values and proves the boot's secret values still come
  # from the credentials (BE-08, SEC-07).
  it "reads every production secret from the credentials while sentinel ENV values are set" do
    config = production_config

    expect(config["database_password"]).to be_present
    expect(config["database_password"]).to eq(config["credentials_database_password"])
    expect(config["migration_database_password"]).to eq(config["credentials_migration_password"])
    expect(config["secret_key_base"]).to eq(config["credentials_secret_key_base"])
    expect(config["encryption_primary_key"]).to eq(config["credentials_encryption_primary_key"])
    expect(config["encryption_deterministic_key"]).to eq(config["credentials_encryption_deterministic_key"])
    expect(config["encryption_key_derivation_salt"]).to eq(config["credentials_encryption_key_derivation_salt"])
  end

  it "never boots a production secret from a sentinel ENV value" do
    config = production_config(
      "ACTIVE_STORAGE_SERVICE" => "amazon",
      "AWS_REGION" => "us-east-1",
      "AWS_BUCKET" => "acme-production"
    )

    %w[encryption_deterministic_key encryption_key_derivation_salt amazon_secret_access_key].each do |key|
      expect(config[key]).to be_present
      expect(config[key]).not_to start_with("sentinel-env-")
    end
  end

  it "reads the amazon storage secrets from the credentials while sentinel ENV values are set" do
    config = production_config(
      "ACTIVE_STORAGE_SERVICE" => "amazon",
      "AWS_REGION" => "us-east-1",
      "AWS_BUCKET" => "acme-production"
    )

    expect(config["amazon_access_key_id"]).to be_present
    expect(config["amazon_access_key_id"]).to eq(config["credentials_amazon_access_key_id"])
    expect(config["amazon_secret_access_key"]).to be_present
    expect(config["amazon_secret_access_key"]).to eq(config["credentials_amazon_secret_access_key"])
  end

  it "deletes the production cookie with Secure and Path=/" do
    controller = ApplicationController.new
    jar = double("cookies")
    allow(controller).to receive(:cookies).and_return(jar)
    allow(controller).to receive(:session_cookie_name).and_return("__Host-acme_session_token")
    allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("production"))

    expect(jar).to receive(:delete).with("__Host-acme_session_token", secure: true, path: "/")
    controller.send(:delete_session_cookie!)
  end
end
