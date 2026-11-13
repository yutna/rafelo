require "rails_helper"
require "open3"

RSpec.describe "Production configuration" do
  DUMMY_ENV = {
    "RAILS_ENV" => "production",
    "SECRET_KEY_BASE" => "production-spec-secret",
    "ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY" => "rafelo-test-primary-key-0000001",
    "ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY" => "rafelo-test-deterministic-0001",
    "ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT" => "rafelo-test-salt-000000000001",
    "RAFELO_API_BASE_URL" => "http://localhost:4000",
    "DB_PASSWORD" => "production-spec-password"
  }.freeze

  SCRIPT = <<~'RUBY'
    require "rack/mock"
    app = Rails.application
    request = Rack::MockRequest.new(app)
    puts({
      hosts: app.config.hosts,
      force_ssl: app.config.force_ssl,
      assume_ssl: app.config.assume_ssl,
      excluded: app.config.host_authorization[:exclude].call(Struct.new(:path).new("/up")),
      unknown_host: request.get("/en", "HTTP_HOST" => "evil.test", "HTTPS" => "on").status,
      health: request.get("/up", "HTTP_HOST" => "example.com", "HTTPS" => "on").status
    }.to_json)
  RUBY

  def production_config(env = {})
    output, error, status = Open3.capture3(DUMMY_ENV.merge(env), "bin/rails", "runner", SCRIPT, chdir: Rails.root.to_s)
    raise "production boot failed: #{error}" unless status.success?

    JSON.parse(output.lines.last)
  end

  it "forces SSL, allows only configured hosts, excludes /up and rejects an unknown host" do
    config = production_config("RAILS_HOSTS" => "")

    expect(config["force_ssl"]).to be(true)
    expect(config["assume_ssl"]).to be(true)
    expect(config["hosts"]).to eq([ "example.com" ])
    expect(config["excluded"]).to be(true)
    expect(config["unknown_host"]).to eq(403)
    expect(config["health"]).to eq(200)
  end

  it "reads RAILS_HOST when RAILS_HOSTS is absent" do
    config = production_config("RAILS_HOSTS" => nil, "RAILS_HOST" => "app.example.test")

    expect(config["hosts"]).to eq([ "app.example.test" ])
  end

  it "deletes the production cookie with Secure and Path=/" do
    controller = ApplicationController.new
    jar = double("cookies")
    allow(controller).to receive(:cookies).and_return(jar)
    allow(controller).to receive(:session_cookie_name).and_return("__Host-rafelo_session_token")
    allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("production"))

    expect(jar).to receive(:delete).with("__Host-rafelo_session_token", secure: true, path: "/")
    controller.send(:delete_session_cookie!)
  end
end
