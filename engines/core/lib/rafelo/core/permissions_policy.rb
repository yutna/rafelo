# frozen_string_literal: true

module Rafelo
  module Core
    # Adds the header to every response, including the exceptions app, from a
    # Rack middleware (SEC-13). A controller after-callback would miss errors.
    class PermissionsPolicy
      VALUE = "camera=(), geolocation=(), microphone=()"

      def initialize(app)
        @app = app
      end

      def call(env)
        status, headers, body = @app.call(env)
        headers["Permissions-Policy"] ||= VALUE
        [ status, headers, body ]
      end
    end
  end
end
