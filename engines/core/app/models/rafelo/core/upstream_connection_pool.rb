# frozen_string_literal: true

module Rafelo
  module Core
    # One bounded pool of persistent connections per named upstream for the
    # process (BE-05, BE-21). A call borrows one Faraday connection for the
    # whole request, so its Net::HTTP::Persistent socket is reused across
    # requests and never used by two threads at once. The pool hands back the
    # connection just returned first, so one client's sequential calls reuse
    # one socket.
    #
    # `UpstreamClient` supplies the factory, so only that class names Faraday
    # (ARCH-01).
    #
    # The size is the smaller of the Puma thread count and the upstream's
    # bulkhead (`max_concurrent_calls`): a Puma thread makes one synchronous
    # call at a time, and the bulkhead never admits more calls than that.
    # Waiting for a connection is bounded by the request deadline (BE-16).
    class UpstreamConnectionPool
      MUTEX = Mutex.new

      class << self
        def for(name, config, &factory)
          size = size_for(config)
          key = [ name.to_sym, config.base_url, config.open_timeout, config.read_timeout,
                  config.write_timeout, size ]
          MUTEX.synchronize do
            pools[key] ||= new(size: size, &factory)
          end
        end

        def size_for(config)
          [ puma_threads, config.max_concurrent_calls ].min
        end

        private

        def pools
          @pools ||= {}
        end

        def puma_threads
          threads = Rails.application.config.x.puma_threads
          unless threads.is_a?(Integer) && threads.positive?
            raise "upstream connection pool: puma_threads is not configured"
          end

          threads
        end
      end

      def initialize(size:, &factory)
        @size = size
        @available = Array.new(size) { factory.call }
        @mutex = Mutex.new
        @condition = ConditionVariable.new
      end

      attr_reader :size

      def with(deadline:)
        connection = borrow(deadline)
        begin
          yield connection
        ensure
          release(connection)
        end
      end

      private

      def borrow(deadline)
        @mutex.synchronize do
          loop do
            return @available.pop unless @available.empty?

            remaining = deadline.remaining
            raise ApplicationError.new("upstream.timeout") if remaining <= 0

            @condition.wait(@mutex, remaining)
          end
        end
      end

      def release(connection)
        @mutex.synchronize do
          @available.push(connection)
          @condition.signal
        end
      end
    end
  end
end
