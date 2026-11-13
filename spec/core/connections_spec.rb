require "rails_helper"

RSpec.describe "Connection arithmetic" do
  it "gives each Puma process room for threads, executor and downloads" do
    config = ActiveRecord::Base.configurations.configs_for(env_name: Rails.env).first
    pool = config.max_connections
    puma_threads = Rails.application.config.x.puma_threads
    executor = Rails.application.config.x.executor_threads
    downloads = Rails.application.config.x.downloads.max_concurrent

    expect(pool).to be >= puma_threads + executor + downloads + 1
  end

  it "keeps the deadline above the upstream read timeout and below the proxy" do
    upstream = Rails.application.config.x.upstreams.fetch(:api)
    deadline = Rails.application.config.x.requests.upstream_deadline_seconds
    refresh = Rails.application.config.x.sessions.refresh_timeout_seconds

    expect(deadline).to be > upstream.read_timeout
    expect(refresh).to be > upstream.read_timeout
  end

  it "keeps the connection budget below the server limit" do
    budgets = YAML.load_file(Rails.root.join("config/budgets.yml")).fetch("connections")

    expect(budgets.fetch("budget")).to be < budgets.fetch("server_max_connections")
    expect(budgets.fetch("headroom")).to eq(
      budgets.fetch("server_max_connections") - budgets.fetch("budget")
    )
  end
end
