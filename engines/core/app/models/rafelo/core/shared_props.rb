# frozen_string_literal: true

module Rafelo
  module Core
    # Builds the shared props every Inertia response carries beside the page's
    # five keys. `trace` is an always-prop and is shared separately by the base
    # controller so a partial reload keeps this response's ids (CT-01).
    class SharedProps
      def initialize(context:, request_path:)
        @context = context
        @request_path = request_path
      end

      def to_h
        {
          auth: auth,
          app: app,
          nav: nav
        }
      end

      def trace
        {
          requestId: @context.request_id.to_s,
          traceId: Current.trace_id.to_s.presence || @context.request_id.to_s
        }
      end

      private

      def auth
        viewer = @context.viewer
        return { viewer: nil } unless viewer

        {
          viewer: {
            id: viewer.id.to_s,
            name: viewer.respond_to?(:name) ? viewer.name.to_s : ""
          }
        }
      end

      def app
        {
          name: "Rafelo",
          locale: @context.locale.to_s,
          locales: Locales.available,
          localeHrefs: @context.urls.locale_hrefs(@request_path),
          timeZone: Time.zone.name
        }
      end

      def nav
        Modules.all.map do |entry|
          {
            key: entry.key.to_s,
            label: I18n.t(entry.nav[:label_key], default: entry.key.to_s),
            path: nav_path(entry),
            icon: entry.nav[:icon].to_s,
            current: current_module?(entry)
          }
        end
      end

      def nav_path(entry)
        @context.urls.app_path("/#{@context.locale}#{entry.path}")
      end

      def current_module?(entry)
        @request_path == nav_path(entry) || @request_path.start_with?("#{nav_path(entry)}/")
      end
    end
  end
end
