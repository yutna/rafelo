# frozen_string_literal: true

require "concurrent"

module Rafelo
  module Core
    class Executor
      def initialize(size)
        @pool = Concurrent::FixedThreadPool.new(size)
      end

      def post(&block)
        @pool.post(&block)
      end

      def shutdown
        @pool.shutdown
        @pool.wait_for_termination
      end
    end
  end
end
