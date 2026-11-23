require "rails_helper"
require "erb"
require "yaml"

RSpec.describe "Connection arithmetic" do
  PROFILES = {
    "single-host" => "config/deploy.yml",
    "multi-host" => "config/deploy.multi.yml"
  }.freeze

  def load_yaml(path)
    YAML.safe_load(ERB.new(File.read(Rails.root.join(path))).result, aliases: true)
  end

  def deploy_for(profile)
    load_yaml(PROFILES.fetch(profile))
  end

  def runtime
    {
      executor_size: Rails.application.config.x.executor.size,
      upstream_deadline_seconds: Rails.application.config.x.requests.upstream_deadline_seconds,
      refresh_timeout_seconds: Rails.application.config.x.sessions.refresh_timeout_seconds,
      download_cap: Rails.application.config.x.downloads.max_concurrent
    }
  end

  def with_env(values)
    saved = values.keys.to_h { |key| [ key, ENV[key] ] }
    values.each { |key, value| ENV[key] = value.to_s }
    yield
  ensure
    saved.each { |key, value| value.nil? ? ENV.delete(key) : ENV[key] = value }
  end

  def database_pools
    production = load_yaml("config/database.yml").fetch("production")
    %w[primary migration].to_h do |role|
      config = production.fetch(role)
      unless config.key?("max_connections") || config.key?("pool")
        raise "config/database.yml production.#{role} has no max_connections"
      end

      [ role, ActiveRecord::DatabaseConfigurations::HashConfig.new("production", role, config).max_connections ]
    end
  end

  def arithmetic(profile, deploy: nil, budgets: nil, runtime: nil)
    deploy ||= deploy_for(profile)
    profile_env = deploy.fetch("env").fetch("clear")

    with_env(profile_env) do
      ConnectionArithmetic.new(
        name: profile,
        deploy: deploy,
        database: database_pools,
        queue: load_yaml("config/queue.yml").fetch("production"),
        budgets: budgets || load_yaml("config/budgets.yml"),
        runtime: runtime || self.runtime,
        upstreams: load_yaml("config/upstreams.yml").fetch("production"),
        recurring: load_yaml("config/recurring.yml").fetch("production", {})
      )
    end
  end

  it "reads Puma threads from the same environment variable config/puma.rb uses" do
    puma = File.read(Rails.root.join("config/puma.rb"))

    expect(puma).to include('threads_count = ENV.fetch("RAILS_MAX_THREADS", 3)')
    PROFILES.each_key do |profile|
      deploy = deploy_for(profile)
      expect(arithmetic(profile).puma_threads)
        .to eq(Integer(deploy.fetch("env").fetch("clear").fetch("RAILS_MAX_THREADS")))
    end
  end

  it "sums every process kind and connection role in the single-host profile" do
    report = arithmetic("single-host").check!

    expect(report.process_kinds.map(&:name)).to contain_exactly(
      "puma", "solid_queue_supervisor", "solid_queue_worker", "solid_queue_dispatcher", "solid_queue_scheduler"
    )
    expect(report.total).to eq(2 * 12 + 2 + 5 + 2 + 2)
    expect(report.database.keys).to contain_exactly("primary", "migration")
  end

  it "sums every process kind and connection role in the multi-host profile" do
    report = arithmetic("multi-host").check!

    expect(report.process_kinds.map(&:name)).to contain_exactly(
      "puma", "solid_queue_supervisor", "solid_queue_worker", "solid_queue_dispatcher", "solid_queue_scheduler"
    )
    expect(report.total).to eq(2 * 2 * 12 + 2 + 5 + 2 + 2)
    expect(report.database.keys).to contain_exactly("primary", "migration")
  end

  it "keeps the proxy, request, upstream, and refresh timeouts in order for both profiles" do
    PROFILES.each_key do |profile|
      report = arithmetic(profile).check!

      expect(report.proxy_response_timeout).to be > report.request_deadline
      expect(report.request_deadline).to be > report.upstreams.fetch("api").fetch("read_timeout")
      expect(report.refresh_timeout).to be > report.upstreams.fetch("api").fetch("read_timeout")
    end
  end

  it "fails the single-host canary when Puma workers exceed the budget" do
    deploy = deploy_for("single-host")
    deploy.fetch("env").fetch("clear")["WEB_CONCURRENCY"] = 20

    expect { arithmetic("single-host", deploy: deploy).check! }
      .to raise_error(/BE-21: single-host: .*exceed the budget/)
  end

  it "fails the multi-host canary when job workers exceed the budget" do
    deploy = deploy_for("multi-host")
    deploy.fetch("env").fetch("clear")["JOB_CONCURRENCY"] = 20

    expect { arithmetic("multi-host", deploy: deploy).check! }
      .to raise_error(/BE-21: multi-host: .*exceed the budget/)
  end

  it "fails the pool canary in each profile when the executor grows past the pool" do
    PROFILES.each_key do |profile|
      expect { arithmetic(profile, runtime: runtime.merge(executor_size: 20)).check! }
        .to raise_error(/BE-21: #{profile}: puma can hold .* but the primary pool is 12/)
    end
  end

  it "fails on a missing arithmetic key instead of defaulting it" do
    deploy = deploy_for("single-host")
    deploy.fetch("env").fetch("clear").delete("WEB_CONCURRENCY")

    expect { arithmetic("single-host", deploy: deploy).check! }.to raise_error(KeyError, /WEB_CONCURRENCY/)
  end
end
