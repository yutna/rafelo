# frozen_string_literal: true

require "securerandom"

module Rafelo
  module Core
    # Rails parses a JSON body before the first controller callback, so the
    # small report endpoints must be capped in Rack. The proxy owns the large
    # request cap (SEC-13). The 413 is returned outside the controller stack,
    # so it carries the trace ids and security headers itself.
    class BodyLimit
      PATHS = {
        "/core/client_errors" => 8 * 1024,
        "/core/csp_reports" => 64 * 1024
      }.freeze

      def initialize(app, limits: PATHS)
        @app = app
        @limits = limits
      end

      def call(env)
        limit = limit_for(env["PATH_INFO"].to_s)
        return @app.call(env) unless limit

        declared = env["CONTENT_LENGTH"].to_i
        return too_large(env) if declared.positive? && declared > limit

        input = env["rack.input"]
        return @app.call(env) unless input

        body = input.read(limit + 1) || ""
        return too_large(env) if body.bytesize > limit

        if input.respond_to?(:rewind)
          input.rewind
        else
          env["rack.input"] = StringIO.new(body)
        end
        @app.call(env)
      end

      private

      # Rails accepts a format suffix, a trailing slash, and percent-encoded
      # spellings on the same route; all must reach the same cap (BE-12).
      # Raw PATH_INFO is matched so an encoded suffix cannot slip past.
      def limit_for(path)
        @limits.each do |base, limit|
          return limit if path == base || path.match?(/\A#{Regexp.escape(base)}(?:[.\/;%]|\z)/)
        end
        nil
      end

      def too_large(env)
        request_id = env["rafelo.request_id"].presence ||
                     env["action_dispatch.request_id"].presence ||
                     env["HTTP_X_REQUEST_ID"].presence ||
                     SecureRandom.uuid
        trace_id = env["rafelo.trace_id"].presence || SecureRandom.hex(16)
        payload = {
          error: {
            code: "request.entity_too_large",
            message: I18n.t("core.errors.entity_too_large", default: "The request body is too large."),
            requestId: request_id,
            traceId: trace_id,
            retryable: false
          }
        }
        headers = {
          "Content-Type" => "application/json",
          "Cache-Control" => "no-store",
          "Permissions-Policy" => PermissionsPolicy::VALUE,
          "X-Content-Type-Options" => "nosniff",
          "X-Frame-Options" => "DENY",
          "Referrer-Policy" => "strict-origin-when-cross-origin"
        }
        [ 413, headers, [ payload.to_json ] ]
      end
    end
  end
end
