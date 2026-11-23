require "rails_helper"
require "rake"

RSpec.describe "rafelo:restore:prepare" do
  let(:task) { Rake::Task["rafelo:restore:prepare"] }

  before do
    Rails.application.load_tasks unless Rake::Task.task_defined?("rafelo:restore:prepare")
    task.reenable
  end

  after do
    task.reenable
    ENV.delete("ACME_DATABASE_ROLE")
    ENV.delete("ACME_RESTORE_CONFIRMED")
    ENV.delete("RESTORE_DATABASE_URL")
  end

  def confirm!
    ENV["ACME_DATABASE_ROLE"] = "migration"
    ENV["ACME_RESTORE_CONFIRMED"] = "1"
  end

  def live_database_url
    config = ActiveRecord::Base.connection_db_config.configuration_hash
    user = config[:username] || "postgres"
    password = config[:password]
    credentials = password.present? ? "#{user}:#{password}" : user
    host = config[:host].presence || "localhost"
    port = config[:port] || 5432

    "postgres://#{credentials}@#{host}:#{port}/#{config[:database]}"
  end

  it "refuses without the migration role" do
    ENV["ACME_RESTORE_CONFIRMED"] = "1"

    expect { task.invoke }.to raise_error(SystemExit)
  end

  it "refuses without the explicit confirmation" do
    ENV["ACME_DATABASE_ROLE"] = "migration"

    expect { task.invoke }.to raise_error(SystemExit)
  end

  it "refuses without RESTORE_DATABASE_URL" do
    confirm!

    expect { task.invoke }.to raise_error(SystemExit)
  end

  it "refuses a target that is the live database" do
    confirm!
    ENV["RESTORE_DATABASE_URL"] = live_database_url

    expect { task.invoke }.to raise_error(SystemExit)
  end
end

RSpec.describe "rafelo:restore:prepare against a scratch target", :database_roles,
               if: DatabaseRoleSpecs.available?("rafelo_restore") do
  let(:scratch) { ScratchDatabase.new("rafelo_restore") }
  let(:task) { Rake::Task["rafelo:restore:prepare"] }

  before do
    scratch.create!
    @connection = scratch.connect
    @connection.exec("CREATE TABLE core_sessions (id bigserial PRIMARY KEY)")
    @connection.exec("INSERT INTO core_sessions DEFAULT VALUES")
    options = scratch.options
    credentials = options[:password] ? "#{options[:user]}:#{options[:password]}" : options[:user]
    @url = "postgres://#{credentials}@#{options[:host]}:#{options[:port]}/#{options[:dbname]}"

    Rails.application.load_tasks unless Rake::Task.task_defined?("rafelo:restore:prepare")
    task.reenable
    ENV["ACME_DATABASE_ROLE"] = "migration"
    ENV["ACME_RESTORE_CONFIRMED"] = "1"
    ENV["RESTORE_DATABASE_URL"] = @url
  end

  after do
    task.reenable
    ENV.delete("ACME_DATABASE_ROLE")
    ENV.delete("ACME_RESTORE_CONFIRMED")
    ENV.delete("RESTORE_DATABASE_URL")
    @connection&.close unless @connection&.finished?
    scratch.drop!
    scratch.close
  end

  it "empties the scratch sessions and leaves the live sessions alone" do
    live = Rafelo::Core::Session.create!(
      token_digest: "live-session",
      viewer_id: "7",
      expires_at: 1.hour.from_now
    )

    expect { task.invoke }.not_to raise_error

    expect(@connection.exec("SELECT count(*) FROM core_sessions").getvalue(0, 0)).to eq("0")
    expect(Rafelo::Core::Session.where(id: live.id).exists?).to be(true)
  end
end
