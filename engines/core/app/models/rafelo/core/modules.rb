# frozen_string_literal: true

module Rafelo
  module Core
    module Modules
      RESERVED = %w[up rails_health_check core sign_in root].freeze
      KERNEL_ERROR_PREFIXES = %w[auth upstream resource validation request unexpected].freeze

      Entry = Data.define(:key, :engine, :path, :permission_prefixes, :legacy_paths, :nav, :flag) do
        def route_name = key

        # ARCH-06: a navigation entry links to the engine's own root route; a
        # module whose engine has no root route stays out of navigation.
        def root_route?
          engine.respond_to?(:routes) && engine.routes.routes.any? { |route| route.name == "root" }
        end

        # The permission keys the module declares in its own manifest, used by
        # boot validation to reject a key two modules both declare (BE-03).
        def permission_keys
          return [] unless engine.respond_to?(:root)

          path = engine.root.join("config/permissions.yml")
          return [] unless File.file?(path)

          manifest = YAML.safe_load_file(path, aliases: false) || {}
          return [] unless manifest.is_a?(Hash)

          manifest.flat_map do |prefix, resources|
            next [] unless resources.is_a?(Hash)

            resources.flat_map do |resource, actions|
              Array(actions).map { |action| "#{prefix}:#{resource}:#{action}" }
            end
          end
        end
      end

      class << self
        def register(key:, engine:, path: nil, permission_prefixes: nil, legacy_paths: {}, nav: nil, flag: nil)
          entry = Entry.new(
            key: key.to_sym,
            engine: engine,
            path: path || "/#{key}",
            permission_prefixes: (permission_prefixes || [ key.to_s ]).map(&:to_s),
            legacy_paths: legacy_paths.transform_keys(&:to_s),
            nav: nav || {},
            flag: flag
          )
          validate_entry!(entry)
          entries << entry
          entry
        end

        def all = entries.dup

        def each(&block) = entries.each(&block)

        def for_path(full_path)
          segments = full_path.to_s.split("?").first.to_s.split("/").reject(&:empty?)
          segments.shift if Locales.locale_segment?(segments.first)
          segment = segments.first
          return if segment.nil?

          all.find { |entry| entry.path.split("/")[1] == segment }
        end

        def fetch(key)
          entries.find { |entry| entry.key == key.to_sym } ||
            raise(KeyError, "unknown module #{key.inspect}")
        end

        def reset!
          entries.clear
          entries.concat(@boot_entries || [])
        end

        def validate!
          @boot_entries ||= entries.dup
          entries.group_by(&:key).each do |key, group|
            raise ArgumentError, "duplicate module key #{key.inspect}" if group.length > 1
          end
          entries.group_by(&:path).each do |path, group|
            raise ArgumentError, "duplicate module path #{path.inspect}" if group.length > 1
          end
          nav_orders = entries.filter_map { |entry| entry.nav[:order] }
          raise ArgumentError, "duplicate navigation order" if nav_orders.length != nav_orders.uniq.length
          entries.flat_map { |entry| entry.permission_keys.map { |key| [ key, entry.key ] } }
                 .group_by(&:first)
                 .each do |key, declared|
            modules = declared.map(&:last).uniq
            if modules.length > 1
              raise ArgumentError, "permission key #{key} is declared by #{modules.join(', ')}"
            end
          end
          entries.each { |entry| validate_entry!(entry) }
        end

        # ARCH-06: the app's routes are drawn after the engine initializers, so
        # the reserved-route and mount checks run from config.after_routes_loaded
        # on every load or reload.
        def validate_routes!
          validate!
          names = app_route_names(ignore: entries)
          entries.each do |entry|
            validate_route_entry!(entry, names)
            validate_mount!(entry)
          end
        end

        private

        def validate_route_entry!(entry, names)
          key = entry.key.to_s
          segment = entry.path.split("/")[1].to_s

          [ [ "key", key ], [ "path", segment ] ].each do |label, name|
            raise ArgumentError, "module #{label} is reserved: #{name}" if names.include?(name)
          end
        end

        def validate_mount!(entry)
          return if mounted?(entry)

          raise ArgumentError,
                "module #{entry.key} is not mounted in the app's routes; " \
                "add `mount #{entry.engine} => \"#{entry.path}\", as: :#{entry.route_name}`"
        end

        def mounted?(entry)
          app_routes.any? do |route|
            route.name.to_s == entry.route_name.to_s && route_app(route) == entry.engine
          end
        end

        def route_app(route)
          return unless route.respond_to?(:app)

          app = route.app
          # A mounted engine is wrapped in Mapper::Constraints; every other
          # endpoint answers `app` with itself (Routing::Endpoint#app).
          app = app.app while app.is_a?(ActionDispatch::Routing::Mapper::Constraints)
          app
        end

        def entries
          @entries ||= []
        end

        def validate_entry!(entry)
          key = entry.key.to_s
          segment = entry.path.split("/")[1].to_s
          raise ArgumentError, "module path must start with /: #{entry.path}" unless entry.path.start_with?("/")

          [ [ "key", key ], [ "path", segment ] ].each do |label, name|
            raise ArgumentError, "module #{label} is reserved: #{name}" if reserved?(name)
          end
        end

        def reserved?(name)
          RESERVED.include?(name) ||
            KERNEL_ERROR_PREFIXES.include?(name) ||
            Locales.locale_segment?(name)
        end

        def app_routes
          return [] unless defined?(Rails) && Rails.respond_to?(:application) && Rails.application

          Rails.application.routes.routes
        end

        def app_route_names(ignore: [])
          engines = ignore.map(&:engine)

          routes = app_routes.reject { |route| engines.include?(route_app(route)) }
          names = routes.filter_map(&:name).map(&:to_s)
          segments = routes.filter_map { |route| route.path.spec.to_s[/\A\/([a-z][a-z0-9_]*)/, 1] }
          (names + segments).uniq
        end
      end
    end
  end
end
