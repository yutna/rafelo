# frozen_string_literal: true

module Rafelo
  module Core
    # Rails parses a JSON body before the first controller callback, so the
    # small report endpoints must be capped in Rack. The proxy owns the large
    # request cap (SEC-13).
    class BodyLimit
      PATHS = {
        "/core/client_errors" => 64 * 1024,
        "/core/csp_reports" => 64 * 1024
      }.freeze

      def initialize(app, limits: PATHS)
        @app = app
        @limits = limits
      end

      def call(env)
        limit = @limits[env["PATH_INFO"]]
        return @app.call(env) unless limit

        declared = env["CONTENT_LENGTH"].to_i
        return too_large if declared.positive? && declared > limit

        input = env["rack.input"]
        return @app.call(env) unless input

        body = input.read(limit + 1) || ""
        return too_large if body.bytesize > limit

        if input.respond_to?(:rewind)
          input.rewind
        else
          env["rack.input"] = StringIO.new(body)
        end
        @app.call(env)
      end

      private

      def too_large
        payload = {
          error: {
            code: "request.entity_too_large",
            message: I18n.t("core.errors.entity_too_large", default: "The request body is too large."),
            retryable: false
          }
        }
        [ 413, { "Content-Type" => "application/json", "Cache-Control" => "no-store" }, [ payload.to_json ] ]
      end
    end
  end
end
