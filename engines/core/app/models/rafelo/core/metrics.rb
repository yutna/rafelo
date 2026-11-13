# frozen_string_literal: true

module Rafelo
  module Core
    # Process-local metrics built from the same notifications as the logs
    # (OPS-04). Labels are allow-listed and never include viewer data.
    class Metrics
      BUCKETS = [ 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1.0, 2.5, 5.0, 10.0 ].freeze

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
            record_upstream(payload[:name].to_s, (finished - started))
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

        def record_upstream(name, seconds)
          return if name.empty?

          mutex.synchronize do
            @upstream_calls[name] += 1
            @upstream_time[name] += seconds
          end
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
          mutex.synchronize do
            lines = []
            lines.concat(request_lines)
            lines.concat(upstream_lines)
            @errors.each do |code, count|
              lines << metric("rafelo_errors_total", { code: code }, count)
            end
            @counters.each do |(name, labels), count|
              lines << metric(name, labels, count)
            end
            lines.concat(pool_lines)
            lines.join("\n") + "\n"
          end
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
          @upstream_calls.map do |name, count|
            metric("rafelo_upstream_calls_total", { upstream: name }, count)
          end + @upstream_time.map do |name, seconds|
            metric("rafelo_upstream_duration_seconds_sum", { upstream: name }, seconds.round(6))
          end
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

        def metric(name, labels, value, type: "counter")
          rendered = labels.map { |key, label| "#{key}=\"#{escape(label)}\"" }.join(",")
          prefix = type == "histogram" ? "# TYPE #{name} histogram\n" : ""
          suffix = rendered.empty? ? name : "#{name}{#{rendered}}"
          "#{prefix}#{suffix} #{value}"
        end

        def escape(value)
          value.to_s.gsub(/[\\"\n]/) do |character|
            case character
            when "\\" then "\\\\"
            when '"' then '\\"'
            when "\n" then "\\n"
            end
          end
        end

        def mutex
          @mutex ||= Mutex.new
        end
      end

      reset!
    end
  end
end
