# frozen_string_literal: true

module Rafelo
  module Core
    # Renders the exceptions Rails catches outside a controller (router 404,
    # missing parameter, forgery failure, unhandled StandardError) with the same
    # ids and `no-store` as the in-controller responder.
    class ExceptionsApp
      def self.call(env)
        request = ActionDispatch::Request.new(env)
        status = env["PATH_INFO"].to_s.delete_prefix("/").to_i
        status = 500 unless status.between?(400, 599)
        code = code_for(status)
        locale = locale_for(env, request)
        request_id = request.request_id
        trace_id = request.get_header("rafelo.trace_id").presence ||
                   env["rafelo.trace_id"].presence ||
                   SecureRandom.hex(16)

        payload = I18n.with_locale(locale) do
          {
            error: {
              code: code,
              message: I18n.t(ErrorCatalog.fetch(code).fetch("i18n_key")),
              requestId: request_id,
              traceId: trace_id,
              retryable: ErrorCatalog.fetch(code).fetch("retryable")
            }
          }
        end

        [ status, { "Content-Type" => "application/json", "Cache-Control" => "no-store" }, [ payload.to_json ] ]
      end

      def self.code_for(status)
        case status.to_i
        when 400 then "request.invalid"
        when 404 then "resource.not_found"
        when 422 then "request.csrf_failed"
        else "unexpected"
        end
      end

      def self.locale_for(env, request)
        path = env["action_dispatch.original_path"] || request.path
        segment = path.to_s.split("/")[1]
        Locales.available?(segment) ? segment : Locales.default
      end
    end
  end
end
