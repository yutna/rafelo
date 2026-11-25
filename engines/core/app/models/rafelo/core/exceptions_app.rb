# frozen_string_literal: true

module Rafelo
  module Core
    # Renders the exceptions Rails catches outside a controller (router 404,
    # missing parameter, forgery failure, unhandled StandardError) through the
    # same error page and JSON responder as the in-controller path (CT-06).
    class ExceptionsApp
      def self.call(env)
        request = ActionDispatch::Request.new(env)
        status = env["PATH_INFO"].to_s.delete_prefix("/").to_i
        status = 500 unless status.between?(400, 599)
        code = code_for(status)
        locale = locale_for(env, request)
        request_id = request.request_id.to_s
        trace_id = (request.get_header("rafelo.trace_id").presence ||
                    env["rafelo.trace_id"].presence ||
                    request_id.presence ||
                    SecureRandom.hex(16)).to_s

        unless env["rafelo.error_reported"]
          error = env["action_dispatch.exception"] || ApplicationError.new(code)
          ErrorReporter.report(error, handled: true, code: code, request_id: request_id, trace_id: trace_id)
          env["rafelo.error_reported"] = true
        end

        env["rafelo.exceptions.status"] = status
        env["rafelo.exceptions.code"] = code
        env["rafelo.exceptions.locale"] = locale
        env["rafelo.trace_id"] = trace_id
        ErrorPagesController.action(:show).call(env)
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
