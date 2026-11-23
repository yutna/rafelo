# frozen_string_literal: true

module Rafelo
  module Core
    # Process-local metrics built from the same notifications as the logs
    # (OPS-04). Labels are allow-listed and never include viewer data.
    class Metrics
      BUCKETS = [ 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1.0, 2.5, 5.0, 10.0 ].freeze
      CSP_DIRECTIVES = %w[
        base-uri child-src connect-src default-src font-src form-action frame-ancestors
        frame-src img-src manifest-src media-src object-src prefetch-src report-to
        report-uri require-trusted-types-for sandbox script-src script-src-attr
        script-src-elem style-src style-src-attr style-src-elem trusted-types
        upgrade-insecure-requests worker-src
      ].freeze
      CSP_ORIGINS = %w[inline eval self data: blob: about: javascript: unknown].freeze

      class << self
        def install!
          return if @installed

          ActiveSupport::Notifications.subscribe("process_action.action_controller") do |_, _, _, _, payload|
            record_request(
              controller: payload[:controller].to_s,
              action: payload[:action].to_s,
              status: payload[:status].to_i,
              seconds: payload[:duration].to_f / 1_000.0
            )
          end
          ActiveSupport::Notifications.subscribe("upstream.call") do |_, started, finished, _, payload|
            record_upstream(payload[:name].to_s, (finished - started), gateway: payload[:gateway])
          end
          ActiveSupport::Notifications.subscribe("enqueue.active_job") do |_, _, _, _, payload|
            increment("rafelo_jobs_enqueued_total", { job: payload[:job].class.name })
          end
          ActiveSupport::Notifications.subscribe("perform.active_job") do |_, _, _, _, payload|
            error = payload[:exception_object]
            increment("rafelo_jobs_failed_total", { job: payload[:job].class.name }) if error
          end
          @installed = true
        end

        def reset!
          mutex.synchronize do
            @requests = Hash.new(0)
            @durations = Hash.new { |hash, key| hash[key] = { requests: 0, sum: 0.0, buckets: Hash.new(0) } }
            @upstream_calls = Hash.new(0)
            @upstream_time = Hash.new(0.0)
            @circuits = {}
            @errors = Hash.new(0)
            @counters = Hash.new(0)
          end
        end

        def record_request(controller:, action:, status:, seconds:)
          mutex.synchronize do
            labels = { controller: controller, action: action, status: status.to_s }
            @requests[labels] += 1
            duration = (@durations[labels] ||= { requests: 0, sum: 0.0, buckets: Hash.new(0) })
            duration[:requests] += 1
            duration[:sum] += seconds
            BUCKETS.each { |bucket| duration[:buckets][bucket] += 1 if seconds <= bucket }
            duration[:buckets][Float::INFINITY] += 1
          end
        end

        def record_upstream(name, seconds, gateway: nil)
          return if name.empty?

          labels = { upstream: name.to_s }
          labels[:gateway] = gateway.to_s if gateway.present?
          mutex.synchronize do
            @upstream_calls[labels] += 1
            @upstream_time[labels] += seconds
          end
        end

        def record_upstream_error(name, code, gateway: nil)
          labels = { upstream: name.to_s, code: code.to_s }
          labels[:gateway] = gateway.to_s if gateway.present?
          increment("rafelo_upstream_errors_total", labels)
        end

        def circuit_state(name, gateway, state)
          mutex.synchronize do
            @circuits[[ name.to_s, gateway.to_s ]] = state.to_s
          end
        end

        def circuit_open(name, gateway)
          increment("rafelo_circuit_open_total", { upstream: name.to_s, gateway: gateway.to_s })
        end

        def bulkhead_refused(name)
          increment("rafelo_bulkhead_refused_total", { upstream: name.to_s })
        end

        def csp_report(directive:, blocked_origin:)
          increment("rafelo_csp_reports_total", {
            directive: csp_directive(directive),
            blocked_origin: csp_origin(blocked_origin)
          })
        end

        def record_error(code)
          increment("rafelo_errors_total", { code: code.to_s })
        end

        def token_refresh(success:)
          increment(success ? "rafelo_token_refreshes_total" : "rafelo_token_refresh_failures_total")
        end

        def grants_dropped(count)
          increment("rafelo_grants_dropped_total", {}, count)
        end

        def increment(name, labels = {}, by = 1)
          mutex.synchronize { @counters[[ name, labels.sort.to_h ]] += by }
        end

        def text
          lines = mutex.synchronize do
            collected = []
            collected.concat(request_lines)
            collected.concat(upstream_lines)
            @errors.each do |code, count|
              collected << metric("rafelo_errors_total", { code: code }, count)
            end
            @counters.each do |(name, labels), count|
              collected << metric(name, labels, count)
            end
            collected.concat(circuit_lines)
            collected
          end

          lines.concat(process_lines)
          lines.concat(pool_lines)
          lines.concat(queue_lines)
          lines.concat(table_health_lines)
          lines.join("\n") + "\n"
        end

        private

        def request_lines
          lines = []
          @requests.each do |labels, count|
            lines << metric("rafelo_requests_total", labels, count)
          end
          @durations.each do |labels, data|
            lines << metric("rafelo_request_duration_seconds_count", labels, data[:requests])
            lines << metric("rafelo_request_duration_seconds_sum", labels, data[:sum].round(6))
            data[:buckets].each do |bucket, count|
              le = bucket == Float::INFINITY ? "+Inf" : bucket.to_s
              lines << metric("rafelo_request_duration_seconds_bucket", labels.merge(le: le), count)
            end
          end
          lines
        end

        def upstream_lines
          @upstream_calls.map do |labels, count|
            metric("rafelo_upstream_calls_total", labels, count)
          end + @upstream_time.map do |labels, seconds|
            metric("rafelo_upstream_duration_seconds_sum", labels, seconds.round(6))
          end
        end

        def circuit_lines
          @circuits.map do |(upstream, gateway), state|
            metric(
              "rafelo_circuit_state",
              { upstream: upstream, gateway: gateway, state: state },
              1,
              type: "gauge"
            )
          end
        end

        def process_lines
          identity = ProcessIdentity.to_h
          [
            metric(
              "rafelo_process_info",
              { host: identity[:host], pid: identity[:pid], role: identity[:role] },
              1,
              type: "gauge"
            )
          ]
        end

        def pool_lines
          return [] unless defined?(ActiveRecord::Base) && ActiveRecord::Base.connected?

          stat = ActiveRecord::Base.connection_pool.stat
          [
            metric("rafelo_db_pool_size", {}, stat.fetch(:size)),
            metric("rafelo_db_pool_busy", {}, stat.fetch(:busy)),
            metric("rafelo_db_pool_waiting", {}, stat.fetch(:waiting))
          ]
        rescue StandardError
          []
        end

        def queue_lines
          return [] unless defined?(SolidQueue::ReadyExecution) && ActiveRecord::Base.connected?

          ready = SolidQueue::ReadyExecution
          oldest = ready.minimum(:created_at)
          latency = oldest ? (Time.current - oldest).round(3) : 0
          [
            metric("rafelo_jobs_ready", {}, ready.count, type: "gauge"),
            metric("rafelo_jobs_ready_latency_seconds", {}, latency, type: "gauge")
          ]
        rescue StandardError
          []
        end

        def table_health_lines
          return [] unless defined?(ActiveRecord::Base) && ActiveRecord::Base.connected?

          rows = ActiveRecord::Base.connection.select_all(<<~SQL)
            SELECT relname, n_dead_tup, n_live_tup, n_tup_hot_upd, n_tup_upd
            FROM pg_stat_user_tables
            WHERE relname IN ('core_sessions', 'core_idempotency_keys', 'solid_queue_jobs')
          SQL
          rows.flat_map do |row|
            live = row["n_live_tup"].to_i + row["n_dead_tup"].to_i
            dead_ratio = live.zero? ? 0.0 : row["n_dead_tup"].to_f / live
            updates = row["n_tup_upd"].to_i
            hot_updates = row["n_tup_hot_upd"].to_i
            hot_ratio = updates.zero? ? 0.0 : hot_updates.to_f / [ updates, hot_updates ].max
            [
              metric("rafelo_db_dead_tuple_ratio", { table: row["relname"] }, dead_ratio.round(4), type: "gauge"),
              metric("rafelo_db_hot_update_ratio", { table: row["relname"] }, hot_ratio.round(4), type: "gauge")
            ]
          end
        rescue StandardError
          []
        end

        def csp_directive(value)
          name = value.to_s.downcase.split.first.to_s
          CSP_DIRECTIVES.include?(name) ? name : "other"
        end

        def csp_origin(value)
          value = value.to_s.downcase
          return value if CSP_ORIGINS.include?(value)
          return "external" if value.start_with?("http://", "https://")

          "other"
        end

        def metric(name, labels, value, type: nil)
          rendered = labels.map { |key, label| "#{key}=\"#{escape(label)}\"" }.join(",")
          suffix = rendered.empty? ? name : "#{name}{#{rendered}}"
          "#{suffix} #{value}"
        end

        def escape(value)
          value.to_s.gsub("\\", "\\\\").gsub('"', '\\"').gsub("\n", "\\n")
            .gsub(/[\x00-\x08\x0b\x0c\x0e-\x1f\x7f]/, "")
        end

        def mutex
          @mutex ||= Mutex.new
        end
      end

      reset!
    end
  end
end
