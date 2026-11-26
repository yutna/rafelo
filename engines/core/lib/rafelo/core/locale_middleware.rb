# frozen_string_literal: true

module Rafelo
  module Core
    class LocaleMiddleware
      EXEMPT_PREFIXES = %w[/up /core /rails /cable /.well-known /vite /vite-dev /vite-test].freeze

      def initialize(app)
        @app = app
      end

      def call(env)
        request = Rack::Request.new(env)
        path = request.path_info
        return @app.call(env) if exempt?(path)

        segment = path.split("/")[1]
        if segment && Locales.locale_segment?(segment)
          return not_found unless Locales.available?(segment)

          return I18n.with_locale(segment) { @app.call(env) } unless trailing_slash?(path)

          return redirect(with_query(path.chomp("/"), request))
        end

        return redirect(with_query(locale_path(path), request)) if request.get? || request.head?

        not_found
      end

      private

      def exempt?(path)
        return true if EXEMPT_PREFIXES.any? { |prefix| path == prefix || path.start_with?("#{prefix}/") }

        file = Rails.root.join("public", path.delete_prefix("/"))
        File.file?(file)
      end

      def trailing_slash?(path)
        path.length > 1 && path.end_with?("/")
      end

      def locale_path(path)
        path == "/" ? "/#{Locales.default}" : "/#{Locales.default}#{path}"
      end

      def with_query(path, request)
        request.query_string.empty? ? path : "#{path}?#{request.query_string}"
      end

      def redirect(path)
        [ 302, { "Location" => path }, [] ]
      end

      def not_found
        raise ActionController::RoutingError, "Not Found"
      end
    end
  end
end
