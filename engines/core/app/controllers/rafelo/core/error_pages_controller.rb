# frozen_string_literal: true

module Rafelo
  module Core
    # The endpoint behind `config.exceptions_app`. It renders the same error
    # page as the in-controller responder for HTML and Inertia, and the JSON
    # body for non-Inertia JSON callers (CT-06). It reads no session; the ids
    # come from the request and the locale from the original path.
    class ErrorPagesController < ActionController::Base
      layout "application"
      protect_from_forgery with: :exception
      rescue_from ActionController::InvalidAuthenticityToken, with: :render_forgery_error

      def show
        status = request.env.fetch("rafelo.exceptions.status", 500)
        code = request.env.fetch("rafelo.exceptions.code", "unexpected")
        locale = request.env.fetch("rafelo.exceptions.locale", Locales.default)

        I18n.with_locale(locale) do
          error = ApplicationError.new(code)
          context = PageContextFactory.build(
            session: nil,
            flags: Flags.current,
            locale: I18n.locale,
            request_id: request.request_id,
            trace_id: request.env["rafelo.trace_id"].presence || request.request_id,
            urls: Urls.new(locale: I18n.locale, router: Rails.application.routes.mounted_helpers)
          )
          set_security_headers(status)
          shared = SharedProps.new(context: context, request_path: original_path).to_h

          if request.headers["X-Inertia"] == "true" || request.format.html?
            render inertia: "errors/show",
                   props: shared.merge(ErrorShowProps.new(context: context, error: error).to_inertia),
                   status: status
          else
            render json: { error: error_payload(error, context) }, status: status
          end
        end
      end

      private

      # The re-dispatched request already carries the original status and code
      # in the env (ExceptionsApp). A tokenless write must not be rewritten to
      # 422 when the original error was a 500; a genuine forgery already
      # arrives as 422 request.csrf_failed.
      def render_forgery_error
        show
      end

      def original_path
        request.env["action_dispatch.original_path"] || request.path
      end

      def set_security_headers(status)
        response.headers["Cache-Control"] = "no-store"
        request.content_security_policy_nonce ||= SecureRandom.urlsafe_base64(16)
        policy = request.content_security_policy
        return unless policy

        header = if Rails.application.config.content_security_policy_report_only
          "Content-Security-Policy-Report-Only"
        else
          "Content-Security-Policy"
        end
        response.headers[header] = policy.build(request, request.content_security_policy_nonce)
        response.headers["Cache-Control"] = "no-store"
        response.status = status
      end

      def error_payload(error, context)
        {
          code: error.code,
          message: error.message,
          requestId: context.request_id.to_s,
          traceId: context.trace_id.to_s,
          retryable: error.retryable?
        }
      end
    end
  end
end
