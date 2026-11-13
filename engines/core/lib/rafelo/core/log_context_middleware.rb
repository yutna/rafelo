# frozen_string_literal: true

module Rafelo
  module Core
    # Gives each request its own log collector before the controller stack
    # runs, so the Lograge line sees the request's SQL and upstream counts
    # (OPS-01, OPS-02).
    class LogContextMiddleware
      def initialize(app)
        @app = app
        RequestLog.install!
      end

      def call(env)
        log = RequestLog.new
        previous = RequestLog.current
        RequestLog.current = log
        env["rafelo.request_log"] = log
        @app.call(env)
      ensure
        RequestLog.current = previous
      end
    end
  end
end
