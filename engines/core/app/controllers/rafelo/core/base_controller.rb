# frozen_string_literal: true

module Rafelo
  module Core
    class BaseController < ActionController::Base
      include Pundit::Authorization

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
