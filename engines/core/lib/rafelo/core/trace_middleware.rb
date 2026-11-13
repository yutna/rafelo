# frozen_string_literal: true

require "securerandom"

module Rafelo
  module Core
    # Records the request and trace ids in the request env before the body
    # limit runs, so a middleware response (413) can carry them (SEC-09,
    # SEC-13, OPS-02). ActionDispatch::RequestId has already read the incoming
    # X-Request-Id header when this middleware runs.
    #
    # An incoming W3C traceparent is accepted only when it matches the Trace
    # Context grammar; anything else starts a new trace and is never logged.
    class TraceMiddleware
      TRACEPARENT = /\A([0-9a-f]{2})-([0-9a-f]{32})-([0-9a-f]{16})-([0-9a-f]{2})(?:-(.*))?\z/
      ZERO_TRACE = "0" * 32
      ZERO_PARENT = "0" * 16

      def self.parse(value)
        return unless value.is_a?(String)

        match = TRACEPARENT.match(value)
        return unless match

        version, trace_id, parent_id, flags, tail = match.captures
        return if version == "ff"
        return if version == "00" && !tail.nil?
        return if trace_id == ZERO_TRACE || parent_id == ZERO_PARENT

        { trace_id: trace_id, sampled: flags.to_i(16).anybits?(1) }
      end

      def self.fresh_trace
        loop do
          trace_id = SecureRandom.hex(16)
          return { trace_id: trace_id, sampled: false } unless trace_id == ZERO_TRACE
        end
      end

      def initialize(app)
        @app = app
      end

      def call(env)
        request_id = env["action_dispatch.request_id"].presence ||
                     env["HTTP_X_REQUEST_ID"].presence ||
                     SecureRandom.uuid
        trace = self.class.parse(env["HTTP_TRACEPARENT"]) || self.class.fresh_trace
        env["rafelo.request_id"] = request_id
        env["rafelo.trace_id"] = trace.fetch(:trace_id)
        env["rafelo.trace_sampled"] = trace.fetch(:sampled)
        Current.request_id = request_id
        Current.trace_id = trace.fetch(:trace_id)
        Current.trace_sampled = trace.fetch(:sampled)
        @app.call(env)
      end
    end
  end
end
