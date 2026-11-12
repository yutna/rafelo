# frozen_string_literal: true

module Rafelo
  module Core
    # Builds every application URL a page needs for one request and records
    # the paths it built, so a request-spec matcher can prove that every href
    # in the props resolves.
    class Urls
      attr_reader :built

      def initialize(locale:, router: Rails.application.routes.mounted_helpers)
        @locale = locale.to_sym
        @router = router
        @built = []
      end

      def locale_hrefs(request_path)
        Locales.available.map do |locale|
          href = request_path.sub(%r{\A/[a-z]{2}(?=/|\z)}, "/#{locale}")
          href = "/#{locale}" if href == request_path && request_path == "/"
          @built << href
          { locale: locale, href: href }
        end
      end

      def route(engine_key, route_name, **params)
        proxy = @router.public_send(engine_key)
        path = proxy.public_send("#{route_name}_path", locale: @locale, **params)
        @built << path
        path
      rescue NoMethodError
        raise ArgumentError, "unknown route #{engine_key}.#{route_name}"
      end
    end
  end
end
