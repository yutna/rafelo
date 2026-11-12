# frozen_string_literal: true

module Rafelo
  module Core
    class RequestDeadline
      def initialize(seconds)
        @expires_at = now + seconds.to_f
      end

      def remaining
        [ @expires_at - now, 0.0 ].max
      end

      def expired?
        remaining.zero?
      end

      private

      def now
        Process.clock_gettime(Process::CLOCK_MONOTONIC)
      end
    end
  end
end
