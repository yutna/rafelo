# frozen_string_literal: true

require "securerandom"

module Rafelo
  module Core
    # Records the request and trace ids in the request env before the body
    # limit runs, so a middleware response (413) can carry them (SEC-09,
    # SEC-13, OPS-02). ActionDispatch::RequestId has already read the incoming
    # X-Request-Id header when this middleware runs.
    class TraceMiddleware
      def initialize(app)
        @app = app
      end

      def call(env)
        request_id = env["action_dispatch.request_id"].presence ||
                     env["HTTP_X_REQUEST_ID"].presence ||
                     SecureRandom.uuid
        env["rafelo.request_id"] = request_id
        env["rafelo.trace_id"] = env["HTTP_X_REQUEST_ID"].presence || request_id
        @app.call(env)
      end
    end
  end
end
