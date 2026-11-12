# frozen_string_literal: true

module Rafelo
  module Core
    class Bulkhead
      def initialize(limit, wait: 0.1)
        @limit = limit
        @wait = wait
        @in_use = 0
        @mutex = Mutex.new
        @condition = ConditionVariable.new
      end

      def call
        acquire
        yield
      ensure
        release
      end

      private

      def acquire
        deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + @wait
        @mutex.synchronize do
          while @in_use >= @limit
            remaining = deadline - Process.clock_gettime(Process::CLOCK_MONOTONIC)
            raise ApplicationError.new("upstream.unavailable") if remaining <= 0

            @condition.wait(@mutex, remaining)
          end
          @in_use += 1
        end
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
