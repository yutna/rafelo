require "rails_helper"

RSpec.describe "Connection arithmetic" do
  it "gives each Puma process room for threads, executor and downloads" do
    config = ActiveRecord::Base.configurations.configs_for(env_name: Rails.env).first
    pool = config.max_connections
    threads = Rails.application.config.x.executor.size
    downloads = Rails.application.config.x.downloads.max_concurrent

    expect(pool).to be >= threads + downloads + 1
  end

  it "keeps the deadline above the upstream read timeout and below the proxy" do
    upstream = Rails.application.config.x.upstreams.fetch(:api)
    deadline = Rails.application.config.x.requests.upstream_deadline_seconds

    expect(deadline).to be > upstream.read_timeout
  end
end
