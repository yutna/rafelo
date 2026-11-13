# frozen_string_literal: true

require "json"
require "yaml"

module Rafelo
  module Core
    # Walks a Rails route set in-process and checks it against the committed
    # allow-list plus the routes derived from the module registry (SEC-12).
    # The allow-list is never derived from the route set under check.
    class ProductionRoutes
      Route = Data.define(:verb, :path, :to, :kind)
      SUPPORTED_KINDS = %w[dispatch mount legacy_redirect].freeze
      ALLOWED_MOUNTS = %w[ActionCable::Server::Base].freeze
      SINGLE_VERB = /\A[A-Z]+\z/

      class << self
        def walk(route_set, prefix: "", known_engines: nil)
          routes = []
          route_set.routes.each do |route|
            path = join(prefix, route.path.spec.to_s)
            app = unwrap(route.app)
            if engine?(app)
              if known_engines.nil? || known_engines.include?(app)
                routes.concat(walk(app.routes, prefix: path, known_engines: known_engines))
              else
                routes << Route.new(verb: route.verb.to_s, path: normalize_path(path),
                                    to: app.name, kind: "unknown")
              end
            else
              routes << classify(route, app, path)
            end
          end
          routes
        end

        def module_routes(modules)
          modules.flat_map do |entry|
            prefix = "/:locale#{entry.path}"
            routes = walk(entry.engine.routes, prefix: prefix)
            routes + entry.legacy_paths.map do |old_prefix, _target|
              Route.new(verb: "GET", path: normalize_path("#{prefix}/#{old_prefix}(/*rest)"),
                        to: "legacy_redirect", kind: "legacy_redirect")
            end
          end
        end

        def load_allow_list(path)
          document = YAML.safe_load_file(path, aliases: true) || {}
          Array(document.fetch("routes")).map do |row|
            Route.new(
              verb: row.fetch("verb").to_s,
              path: normalize_path(row.fetch("path").to_s),
              to: row.fetch("to").to_s,
              kind: row.fetch("kind", "dispatch").to_s
            )
          end
        end

        def check(walked:, allow_list:, module_routes:)
          errors = []
          errors << "empty walk" if walked.empty?
          expected = (allow_list + module_routes).uniq
          expected_keys = expected.map { |route| key(route) }
          walked_keys = walked.map { |route| key(route) }

          walked.each do |route|
            if unclassifiable?(route)
              errors << "unclassified: #{describe(route)}"
              next
            end

            errors << "not allow-listed: #{describe(route)}" unless expected_keys.include?(key(route))
          end

          expected.each do |route|
            errors << "listed but missing: #{describe(route)}" unless walked_keys.include?(key(route))
          end

          errors
        end

        def describe(route)
          "#{route.verb.to_s.empty? ? 'MOUNT' : route.verb} #{route.path} #{route.to} (#{route.kind})"
        end

        def key(route)
          [ route.verb, route.path, route.to, route.kind ]
        end

        def unclassifiable?(route)
          return true unless SUPPORTED_KINDS.include?(route.kind)
          return true if route.kind == "mount" && !ALLOWED_MOUNTS.include?(route.to)

          false
        end

        def join(prefix, path)
          combined = "#{prefix}#{path}"
          combined = "/#{combined}" unless combined.start_with?("/")
          combined.squeeze("/")
        end

        def normalize_path(path)
          path.sub(/\(\.:format\)\z/, "").squeeze("/")
        end

        private

        def unwrap(app)
          app.respond_to?(:app) ? app.app : app
        end

        def engine?(app)
          app.respond_to?(:routes) && app.respond_to?(:root)
        end

        def classify(route, app, path)
          path = normalize_path(path)
          verb = route.verb.to_s
          unless verb.match?(SINGLE_VERB)
            return mount(app, verb, path) if verb.empty? && mount?(app)

            return Route.new(verb: verb, path: path, to: app.class.name, kind: "unknown")
          end

          if app.is_a?(Rafelo::Core::LegacyRedirect)
            return Route.new(verb: verb, path: path, to: "legacy_redirect", kind: "legacy_redirect")
          end

          if app.is_a?(Proc) || redirect?(app)
            return Route.new(verb: verb, path: path, to: app.class.name, kind: "unknown")
          end

          if !route.defaults[:controller].to_s.empty? && !route.defaults[:action].to_s.empty?
            return Route.new(
              verb: verb,
              path: path,
              to: "#{route.defaults[:controller]}##{route.defaults[:action]}",
              kind: "dispatch"
            )
          end

          mount(app, verb, path)
        end

        def mount?(app)
          app.respond_to?(:call) && !dispatcher?(app) && !app.is_a?(Rafelo::Core::LegacyRedirect) &&
            !app.is_a?(Proc) && !redirect?(app)
        end

        def redirect?(app)
          app.class.name == "ActionDispatch::Routing::Redirect"
        end

        def mount(app, verb, path)
          Route.new(verb: verb, path: path, to: app.class.name, kind: "mount")
        end

        def dispatcher?(app)
          app.class.name == "ActionDispatch::Routing::RouteSet::Dispatcher"
        end
      end
    end
  end
end
