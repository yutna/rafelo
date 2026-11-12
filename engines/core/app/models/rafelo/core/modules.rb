# frozen_string_literal: true

module Rafelo
  module Core
    module Modules
      RESERVED = %w[up rails_health_check core sign_in root].freeze

      Entry = Data.define(:key, :engine, :path, :permission_prefixes, :legacy_paths, :nav, :flag) do
        def route_name = key
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

        def fetch(key)
          entries.find { |entry| entry.key == key.to_sym } ||
            raise(KeyError, "unknown module #{key.inspect}")
        end

        def reset!
          entries.clear
        end

        def validate!
          entries.group_by(&:key).each do |key, group|
            raise ArgumentError, "duplicate module key #{key.inspect}" if group.length > 1
          end
          entries.group_by(&:path).each do |path, group|
            raise ArgumentError, "duplicate module path #{path.inspect}" if group.length > 1
          end
          nav_orders = entries.filter_map { |entry| entry.nav[:order] }
          raise ArgumentError, "duplicate navigation order" if nav_orders.length != nav_orders.uniq.length
          entries.each { |entry| validate_entry!(entry) }
        end

        private

        def entries
          @entries ||= []
        end

        def validate_entry!(entry)
          key = entry.key.to_s
          raise ArgumentError, "module key is reserved: #{key}" if RESERVED.include?(key)
          raise ArgumentError, "module key looks like a locale: #{key}" if Locales.locale_segment?(key)
          raise ArgumentError, "module path must start with /: #{entry.path}" unless entry.path.start_with?("/")
          raise ArgumentError, "module path is reserved: #{entry.path}" if RESERVED.include?(entry.path.delete_prefix("/"))
        end
      end
    end
  end
end
