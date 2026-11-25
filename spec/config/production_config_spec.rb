require "rails_helper"
require "open3"

RSpec.describe "Production configuration" do
  DUMMY_ENV = {
    "RAILS_ENV" => "production",
    "RAILS_MASTER_KEY" => File.read(Rails.root.join("config/credentials/dummy.key")).strip,
    "ACME_API_BASE_URL" => "http://localhost:4000",
    "RAILS_HOSTS" => "example.com",
    "DB_USER" => "acme_runtime"
  }.freeze

  SCRIPT = <<~'RUBY'
    require "rack/mock"
    app = Rails.application
    request = Rack::MockRequest.new(app)
    page = request.get("/en", "HTTP_HOST" => "example.com", "HTTPS" => "on")
    puts({
      hosts: app.config.hosts,
      runtime_role: app.config.x.database.runtime_role,
      force_ssl: app.config.force_ssl,
      assume_ssl: app.config.assume_ssl,
      excluded: app.config.host_authorization[:exclude].call(Struct.new(:path).new("/up")),
      unknown_host: request.get("/en", "HTTP_HOST" => "evil.test", "HTTPS" => "on").status,
      health: request.get("/up", "HTTP_HOST" => "example.com", "HTTPS" => "on").status,
      csp: page.headers["Content-Security-Policy"],
      csp_report_only: page.headers["Content-Security-Policy-Report-Only"]
    }.to_json)
  RUBY

  # The production boot reads every secret from the encrypted production
  # credentials. The specs use the committed dummy credentials, encrypted with
  # the committed dummy key, so they hold no real secret (BE-08, SEC-07).
  def with_dummy_production_credentials
    path = Rails.root.join("config/credentials/production.yml.enc")
    original = File.binread(path)
    FileUtils.cp(Rails.root.join("config/credentials/dummy.yml.enc"), path)
    yield
  ensure
    File.binwrite(path, original) if original
  end

  def production_config(env = {})
    with_dummy_production_credentials do
      output, error, status = Open3.capture3(DUMMY_ENV.merge(env), "bin/rails", "runner", SCRIPT, chdir: Rails.root.to_s)
      raise "production boot failed: #{error}" unless status.success?

      JSON.parse(output.lines.last)
    end
  end

  it "forces SSL, allows only configured hosts, excludes /up and rejects an unknown host" do
    config = production_config

    expect(config["force_ssl"]).to be(true)
    expect(config["assume_ssl"]).to be(true)
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

  it "enforces CSP by default and reports only when CSP_REPORT_ONLY is true" do
    enforced = production_config
    expect(enforced["csp"]).to be_present
    expect(enforced["csp_report_only"]).to be_nil

    report_only = production_config("CSP_REPORT_ONLY" => "true")
    expect(report_only["csp"]).to be_nil
    expect(report_only["csp_report_only"]).to be_present
  end

  it "reads RAILS_HOST when RAILS_HOSTS is absent" do
    config = production_config("RAILS_HOSTS" => nil, "RAILS_HOST" => "app.example.test")

    expect(config["hosts"]).to eq([ "app.example.test" ])
  end

  it "reads production secrets only from credentials, never the old ENV fallbacks" do
    expect(File.read(Rails.root.join("config/initializers/active_record_encryption.rb"))).not_to include("ENV[")
    expect(File.read(Rails.root.join("config/database.yml"))).not_to include('ENV["DB_PASSWORD"].presence')
    expect(File.read(Rails.root.join("config/database.yml"))).not_to include('ENV["DB_MIGRATION_PASSWORD"].presence')
    expect(File.read(Rails.root.join("config/storage.yml"))).not_to include('ENV["AWS_ACCESS_KEY_ID"]')
    expect(File.read(Rails.root.join("config/storage.yml"))).not_to include('ENV["AWS_SECRET_ACCESS_KEY"]')
    expect(File.read(Rails.root.join("config/environments/production.rb"))).not_to match(/^\s*config\.require_master_key\s*=/)
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
