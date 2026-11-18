# frozen_string_literal: true

require "concurrent"

module Rafelo
  module Core
    class Executor
      class << self
        def semaphore(size)
          @semaphores ||= {}
          @semaphores[size] ||= Concurrent::Semaphore.new(size)
        end

        def reset_semaphores!
          @semaphores = {}
        end
      end

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
