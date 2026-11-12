# frozen_string_literal: true

module Rafelo
  module Core
    class BaseController < ActionController::Base
      include Pundit::Authorization
      include Rails.application.routes.mounted_helpers

      rescue_from Pundit::NotAuthorizedError, Pundit::AuthorizationNotPerformedError, with: :deny_access
      rescue_from ApplicationError, with: :render_application_error

      allow_browser versions: :modern
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

      def shared_props
        SharedProps.new(context: page_context, request_path: request.path).to_h
      end

      def page_context
        @page_context ||= PageContextFactory.build(
          session: Current.session,
          flags: {},
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
