# frozen_string_literal: true

module Rafelo
  module Core
    class BaseController < ActionController::Base
      include Pundit::Authorization

      rescue_from Pundit::NotAuthorizedError, Pundit::AuthorizationNotPerformedError, with: :deny_access

      allow_browser versions: :modern
      before_action :set_response_headers
      before_action :assign_request_context
      around_action :with_locale
      before_action :underscore_param_keys
      after_action :verify_authorized

      def page_context
        @page_context ||= PageContextFactory.build(
          session: Current.session,
          flags: {},
          locale: I18n.locale,
          request_id: Current.request_id,
          urls: Urls.new(locale: I18n.locale)
        )
      end

      private

      def pundit_user
        Current.viewer
      end

      def deny_access
        payload = { error: { code: "auth.forbidden" } }
        if performed?
          response.status = Rack::Utils.status_code(:forbidden)
          response.set_header("Content-Type", "application/json")
          response.body = payload.to_json
        else
          render json: payload, status: :forbidden
        end
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
