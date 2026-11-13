# frozen_string_literal: true

module Rafelo
  module Core
    class CallBudget
      attr_reader :deadline

      def initialize(limits = {}, deadline: nil, **extra)
        @limits = limits.merge(extra).transform_keys(&:to_sym)
        @counts = Hash.new(0)
        @mutex = Mutex.new
        @deadline = deadline
      end

      def consume!(upstream)
        enforce_deadline!
        name = upstream.to_sym
        @mutex.synchronize do
          limit = @limits.fetch(name, 0)
          raise ApplicationError.new("request.throttled") if @counts[name] >= limit

          @counts[name] += 1
        end
      end

      def count(upstream)
        @mutex.synchronize { @counts[upstream.to_sym] }
      end

      def remaining
        return unless @deadline

        [ @deadline - Process.clock_gettime(Process::CLOCK_MONOTONIC), 0 ].max
      end

      private

      def enforce_deadline!
        raise ApplicationError.new("upstream.timeout") if @deadline && remaining <= 0
      end
    end
  end
end
