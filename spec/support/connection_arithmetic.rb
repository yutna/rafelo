# frozen_string_literal: true

# The BE-21 connection and timeout arithmetic for one deployment profile.
# The spec builds it from the real config files; each canary builds it from a
# broken copy and expects #check! to raise before a bad profile ships.
class ConnectionArithmetic
  POLLING_CONNECTIONS = 1
  SUPERVISOR_CONNECTIONS = 2
  DISPATCHER_CONNECTIONS = 2
  SCHEDULER_CONNECTIONS = 2
  QUEUE_OVERHEAD = 2
  KAMAL_DEFAULT_RESPONSE_TIMEOUT = 30
  REQUIRED_ENV_KEYS = %w[RAILS_MAX_THREADS WEB_CONCURRENCY JOB_CONCURRENCY].freeze

  ProcessKind = Data.define(:name, :count, :capacity)

  attr_reader :name, :deploy, :database, :queue, :budgets, :runtime, :upstreams, :recurring

  def initialize(name:, deploy:, database:, queue:, budgets:, runtime:, upstreams:, recurring:)
    @name = name
    @deploy = deploy
    @database = database
    @queue = queue
    @budgets = budgets
    @runtime = runtime
    @upstreams = upstreams
    @recurring = recurring
  end

  def check!
    check_required_keys!
    check_timeouts!
    check_pools!
    check_total!
    self
  end

  # What every process kind can hold at once: a Puma process holds the whole
  # pool, a Solid Queue worker holds its threads plus polling and heartbeat,
  # and the supervisor, dispatcher, and scheduler hold a few connections each.
  def process_kinds
    @process_kinds ||= puma_kinds + solid_queue_kinds
  end

  def total
    process_kinds.sum { |kind| kind.count * kind.capacity }
  end

  def connections
    budgets.fetch("connections")
  end

  def env
    deploy.fetch("env").fetch("clear")
  end

  def puma_threads
    Integer(env.fetch("RAILS_MAX_THREADS"))
  end

  def executor_size
    Integer(runtime.fetch(:executor_size))
  end

  def download_cap
    Integer(runtime.fetch(:download_cap))
  end

  def request_deadline
    Integer(runtime.fetch(:upstream_deadline_seconds))
  end

  def refresh_timeout
    Integer(runtime.fetch(:refresh_timeout_seconds))
  end

  def proxy_response_timeout
    Integer(deploy.dig("proxy", "response_timeout") || KAMAL_DEFAULT_RESPONSE_TIMEOUT)
  end

  private

  def puma_kinds
    count = role_hosts("web") * Integer(env.fetch("WEB_CONCURRENCY"))
    return [] if count.zero?

    [ ProcessKind.new(name: "puma", count: count, capacity: puma_capacity) ]
  end

  def puma_capacity
    puma_threads + executor_size + download_cap + POLLING_CONNECTIONS
  end

  def solid_queue_kinds
    hosts = queue_hosts
    raise "BE-21: #{name}: no Solid Queue host; set SOLID_QUEUE_IN_PUMA or a job role" if hosts.zero?

    [ ProcessKind.new(name: "solid_queue_supervisor", count: hosts, capacity: SUPERVISOR_CONNECTIONS) ] +
      queue_process_kinds(hosts)
  end

  def queue_hosts
    hosts = 0
    hosts += role_hosts("web") if env.key?("SOLID_QUEUE_IN_PUMA")
    hosts += role_hosts("job")
    hosts
  end

  def queue_process_kinds(hosts)
    kinds = queue_entries("workers").flat_map do |worker|
      count = Integer(worker.fetch("processes", 1)) * hosts
      capacity = Integer(worker.fetch("threads", 3)) + QUEUE_OVERHEAD
      [ ProcessKind.new(name: "solid_queue_worker", count: count, capacity: capacity) ]
    end
    queue_entries("dispatchers").each do |_dispatcher|
      kinds << ProcessKind.new(name: "solid_queue_dispatcher", count: hosts, capacity: DISPATCHER_CONNECTIONS)
    end
    if recurring.any?
      kinds << ProcessKind.new(name: "solid_queue_scheduler", count: hosts, capacity: SCHEDULER_CONNECTIONS)
    end
    kinds
  end

  def queue_entries(key)
    entries = queue.fetch(key)
    raise "BE-21: #{name}: config/queue.yml #{key} must be a list" unless entries.is_a?(Array)

    entries
  end

  def role_hosts(role)
    servers = deploy.fetch("servers")
    return 0 unless servers.key?(role)

    entry = servers.fetch(role)
    hosts = entry.is_a?(Hash) ? entry.fetch("hosts") : entry
    list = Array(hosts)
    raise "BE-21: #{name}: the #{role} role has no hosts" if list.empty?

    list.length
  end

  def check_required_keys!
    REQUIRED_ENV_KEYS.each { |key| env.fetch(key) }
  end

  def check_timeouts!
    deadline = request_deadline
    unless proxy_response_timeout > deadline
      raise "BE-21: #{name}: proxy response timeout #{proxy_response_timeout} must exceed the request deadline #{deadline}"
    end

    upstreams.each do |upstream, config|
      read_timeout = Integer(config.fetch("read_timeout"))
      next if deadline > read_timeout

      raise "BE-21: #{name}: request deadline #{deadline} must exceed the #{upstream} read timeout #{read_timeout}"
    end

    token_upstream = runtime.fetch(:token_upstream, "api").to_s
    read_timeout = Integer(upstreams.fetch(token_upstream).fetch("read_timeout"))
    return if refresh_timeout > read_timeout

    raise "BE-21: #{name}: refresh timeout #{refresh_timeout} must exceed the #{token_upstream} read timeout #{read_timeout}"
  end

  def check_pools!
    maximum = process_kinds.map(&:capacity).max
    raise "BE-21: #{name}: no process kind to check" if maximum.nil?

    process_kinds.each do |kind|
      pool = Integer(database.fetch("primary"))
      next if pool >= kind.capacity

      raise "BE-21: #{name}: #{kind.name} can hold #{kind.capacity} connections but the primary pool is #{pool}"
    end

    database.each do |role, pool|
      next if Integer(pool) >= maximum

      raise "BE-21: #{name}: the #{role} pool #{pool} is below the largest process need #{maximum}"
    end
  end

  def check_total!
    server_max = Integer(connections.fetch("server_max_connections"))
    budget = Integer(connections.fetch("budget"))
    headroom = Integer(connections.fetch("headroom"))

    unless budget < server_max
      raise "BE-21: #{name}: connection budget #{budget} must stay below server_max_connections #{server_max}"
    end
    unless headroom == server_max - budget
      raise "BE-21: #{name}: headroom #{headroom} must be the gap between #{server_max} and #{budget}"
    end

    used = total + headroom
    return if used <= budget

    raise "BE-21: #{name}: #{total} connections plus headroom #{headroom} exceed the budget #{budget}"
  end
end
