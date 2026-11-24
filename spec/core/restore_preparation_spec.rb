require "rails_helper"
require "uri"

RSpec.describe Rafelo::Core::RestorePreparation do
  def live_connection_options
    config = ActiveRecord::Base.connection_db_config.configuration_hash
    {
      host: config[:host].presence || "localhost",
      port: config[:port] || 5432,
      user: config[:username] || "postgres",
      password: config[:password],
      database: config[:database]
    }
  end

  it "refuses a URL that reaches the live database through a query parameter" do
    options = live_connection_options
    query = URI.encode_www_form(
      {
        host: options[:host], port: options[:port], user: options[:user],
        password: options[:password], dbname: options[:database]
      }.compact
    )

    expect { described_class.new(url: "postgres:///?#{query}").empty_sessions! }
      .to raise_error(described_class::LiveDatabase, /live database/)
  end

  it "refuses the live cluster even when the target session uses another time zone" do
    options = live_connection_options
    query = URI.encode_www_form(
      {
        host: options[:host], port: options[:port], user: options[:user],
        password: options[:password], dbname: options[:database],
        options: "-c timezone=America/New_York"
      }.compact
    ).gsub("+", "%20")

    expect { described_class.new(url: "postgres:///?#{query}").empty_sessions! }
      .to raise_error(described_class::LiveDatabase, /live database/)
  end

  it "empties every restored session before traffic" do
    Rafelo::Core::Session.create!(
      token_digest: "restored-session",
      viewer_id: "7",
      expires_at: 1.hour.from_now
    )

    described_class.new.empty_sessions!

    expect(Rafelo::Core::Session.count).to eq(0)
  end
end
