# frozen_string_literal: true

module Rafelo
  module Core
    class Bulkhead
      def initialize(limit, wait: 0.1, name: nil)
        @limit = limit
        @wait = wait
        @name = name.to_s
        @in_use = 0
        @mutex = Mutex.new
        @condition = ConditionVariable.new
      end

      def call
        acquired = acquire
        yield
      ensure
        release if acquired
      end

      private

      def acquire
        deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + @wait
        @mutex.synchronize do
          while @in_use >= @limit
            remaining = deadline - Process.clock_gettime(Process::CLOCK_MONOTONIC)
            if remaining <= 0
              Metrics.bulkhead_refused(@name) if @name.present?
              raise ApplicationError.new("upstream.unavailable")
            end

            @condition.wait(@mutex, remaining)
          end
          @in_use += 1
        end
        true
      end

      def release
        @mutex.synchronize do
          @in_use -= 1
          @condition.signal
        end
      end
    end
  end
end
