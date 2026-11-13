# frozen_string_literal: true

module Rafelo
  module Core
    class BaseController < ActionController::Base
      include Pundit::Authorization
      include Throttling
      include Rails.application.routes.mounted_helpers

      rescue_from Pundit::NotAuthorizedError, Pundit::AuthorizationNotPerformedError, with: :deny_access
      rescue_from ApplicationError, with: :render_application_error

      allow_browser versions: :modern, block: :render_unsupported_browser, unless: :browser_check_exempt?
      before_action :load_session
      before_action :require_module_enabled
      before_action :set_response_headers
      before_action :assign_request_context
      before_action :share_trace
      around_action :with_locale
      before_action :underscore_param_keys
      after_action :verify_authorized

      def render_page(component, props:, status: nil)
        page = props.respond_to?(:to_inertia) ? props.to_inertia : props
        validate_page_keys!(page)
        render inertia: component, props: shared_props.merge(page), status: status
      end

      # Used by throttle handlers that run before the base callbacks. The
      # locale comes from the path, not from the around action.
      def render_unsupported_browser
        response.headers["Cache-Control"] = "no-store"
        render template: "rafelo/core/unsupported_browser", layout: false, status: :not_acceptable
      end

      def render_error(code)
        I18n.with_locale(params[:locale] || Locales.default) do
          render_application_error(ApplicationError.new(code))
        end
      end

      # Every write ends in a 303: success, shape failure, upstream 422 or a
      # conflict. Only unexpected failures render the error page (BE-13).
      def redirect_after_write(path, notice: nil, alert: nil, errors: nil)
        AuditRecorder.record(
          controller: self,
          event: "write",
          outcome: errors.present? ? "failure" : "success",
          target: path
        )
        flash[:notice] = notice if notice
        flash[:alert] = alert if alert
        options = { status: :see_other }
        options[:inertia] = { errors: errors } if errors.present?
        redirect_to path, **options
      end

      def gateway(klass)
        klass.new(
          token_provider: Current.token_provider,
          budget: Current.call_budget ||= CallBudget.new(api: 3),
          request_id: Current.request_id,
          trace_id: Current.trace_id
        )
      end

      def shared_props
        SharedProps.new(context: page_context, request_path: request.path).to_h
      end

      def session_cookie_name
        Rails.env.production? ? "__Host-rafelo_session_token" : "session_token"
      end

      def load_session
        token = cookies[session_cookie_name]
        return unless token

        session = Session.find_by_token(token)
        if session.nil? || !session.expires_at.future?
          forget_session!(session)
          return
        end
        if session.last_seen_at && session.last_seen_at < Rails.application.config.x.sessions.idle_timeout_seconds.seconds.ago
          forget_session!(session)
          return
        end
        session.touch_seen! if session.last_seen_at.nil? || session.last_seen_at < Rails.application.config.x.sessions.touch_interval_seconds.seconds.ago

        Current.session = session
        Current.viewer = Viewer.new(id: session.viewer_id, name: session.viewer_name.to_s)
        Current.permissions = PermissionSet.new(session.permission_grants)
        Current.token_provider = ViewerTokenProvider.new(session)
        refresh_session!
      end

      def refresh_session!
        gateway = AuthGateway.new(
          budget: CallBudget.new(api: 3),
          request_id: request.request_id,
          trace_id: request.request_id
        )
        SessionRefresher.new(
          session: Current.session,
          gateway: gateway,
          timeout: Rails.application.config.x.sessions.refresh_timeout_seconds,
          wait: Rails.application.config.x.sessions.refresh_timeout_seconds + 2
        ).call
        Current.token_provider = ViewerTokenProvider.new(Current.session.reload)
        Current.permissions = Current.session.permission_set
      rescue ApplicationError => error
        raise if error.code == "auth.expired"

        Rails.logger.warn("session refresh deferred: #{error.code}")
      rescue ActiveRecord::RecordNotFound
        raise ApplicationError.new("auth.expired")
      end

      def forget_session!(session)
        session&.destroy
        delete_session_cookie!
      end

      def clear_session!
        Current.session&.destroy
        Current.session = nil
        Current.viewer = nil
        Current.permissions = nil
        Current.token_provider = nil
        reset_session
        delete_session_cookie!
      end

      def delete_session_cookie!
        cookies.delete(session_cookie_name, secure: !Rails.env.local?, path: "/")
      end

      def require_module_enabled
        entry = Modules.for_path(request.original_fullpath)
        return unless entry&.flag && !Flags.enabled?(entry.flag)

        raise ActionController::RoutingError, "Not Found"
      end

      def browser_check_exempt?
        request.path.start_with?("/core/")
      end

      def require_viewer
        redirect_to "/#{params[:locale] || Locales.default}/sign_in" unless Current.viewer
      end

      def page_context
        @page_context ||= PageContextFactory.build(
          session: Current.session,
          flags: Flags.current,
          locale: I18n.locale,
          request_id: Current.request_id,
          urls: Urls.new(locale: I18n.locale, router: self)
        )
      end

      private

      def share_trace
        inertia_share trace: InertiaRails.always { shared_props_trace }
      end

      def shared_props_trace
        SharedProps.new(context: page_context, request_path: request.path).trace
      end

      def validate_page_keys!(page)
        keys = page.keys.map(&:to_sym)
        return if keys.sort == PageProps::ENVELOPE_KEYS.sort

        raise ArgumentError, "page props must be exactly #{PageProps::ENVELOPE_KEYS.inspect}: #{keys.inspect}"
      end

      def pundit_user
        Current.viewer
      end

      def deny_access
        render_application_error(ApplicationError.new("auth.forbidden"))
      end

      def render_application_error(error)
        AuditRecorder.record(controller: self, event: "request", outcome: "failure", target: request.path) unless request.get? || request.head?

        if error.code == "auth.expired" && Current.session
          clear_session!
          return redirect_to "/#{I18n.locale}/sign_in", status: :see_other, inertia: { clear_history: true }
        end

        response.headers["Cache-Control"] = "no-store"
        if performed?
          response.status = error.status
          response.set_header("Content-Type", "application/json")
          response.body = error_payload(error).to_json
        elsif request.headers["X-Inertia"] == "true" || request.format.html?
          render_page "errors/show",
                      props: ErrorShowProps.new(context: page_context, error: error),
                      status: error.status
        else
          render json: error_payload(error), status: error.status
        end
      end

      def error_payload(error)
        {
          error: {
            code: error.code,
            message: error.message,
            requestId: Current.request_id.to_s,
            traceId: (Current.trace_id.to_s.presence || Current.request_id.to_s),
            retryable: error.retryable?
          }
        }
      end

      def set_response_headers
        response.headers["Cache-Control"] = "no-store"
      end

      def assign_request_context
        Current.request_id = request.request_id
        Current.trace_id = request.env["rafelo.trace_id"]
      end

      def with_locale(&block)
        I18n.with_locale(params[:locale] || Locales.default, &block)
      end

      def underscore_param_keys
        params.deep_transform_keys!(&:underscore)
      end
    end
  end
end
