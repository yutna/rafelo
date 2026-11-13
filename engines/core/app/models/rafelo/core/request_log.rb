# frozen_string_literal: true

module Rafelo
  module Core
    # Counts the request's SQL queries and upstream calls from the same
    # notifications the page budgets use (OPS-01, TS-02). The collector is
    # stored in IsolatedExecutionState, so parallel requests in one process do
    # not mix their counts.
    class RequestLog
      STATE_KEY = :rafelo_request_log

      class << self
        def install!
          return if @installed

          ActiveSupport::Notifications.subscribe("sql.active_record") do |*, payload|
            current&.record_sql(payload)
          end
          ActiveSupport::Notifications.subscribe("upstream.call") do |_, started, finished, _, payload|
            current&.record_upstream(payload, (finished - started) * 1000.0)
          end
          @installed = true
        end

        def current
          ActiveSupport::IsolatedExecutionState[STATE_KEY]
        end

        def current=(log)
          ActiveSupport::IsolatedExecutionState[STATE_KEY] = log
        end
      end

      attr_reader :sql_count, :upstream_calls, :upstream_time

      def initialize
        @sql_count = 0
        @upstream_calls = Hash.new(0)
        @upstream_time = Hash.new(0.0)
      end

      def record_sql(payload)
        return if payload[:cached]

        name = payload[:name].to_s
        return if name == "SCHEMA" || name == "TRANSACTION"

        @sql_count += 1
      end

      def record_upstream(payload, duration_ms)
        name = payload[:name].to_s
        return if name.empty?

        @upstream_calls[name] += 1
        @upstream_time[name] += duration_ms
      end

      def to_h
        {
          sql_count: @sql_count,
          upstream_calls: @upstream_calls.to_h,
          upstream_time: @upstream_time.transform_values { |value| value.round(2) }
        }
      end
    end
  end
end
