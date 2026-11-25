# frozen_string_literal: true

module Rafelo
  module Core
    class ScopedCache
      SCOPES = %i[public viewer].freeze

      def self.fetch(scope:, key:, ttl:, viewer: nil, grants: nil, locale: nil, schema_version: nil, **options)
        module_name = options[:module]
        unknown = options.keys - [ :module ]
        raise ArgumentError, "unknown cache options: #{unknown.inspect}" if unknown.any?

        scope = scope.to_sym
        raise ArgumentError, "unknown cache scope #{scope.inspect}" unless SCOPES.include?(scope)
        raise ArgumentError, "module is required" if module_name.nil?
        raise ArgumentError, "a viewer cache needs a viewer" if scope == :viewer && viewer.nil?
        raise ArgumentError, "a public cache must not carry viewer data" if scope == :public && (viewer || grants)

        caller_engine = caller_locations(1, 5).filter_map { |location| location.path[%r{/engines/([^/]+)/}, 1] }.first
        if caller_engine && caller_engine != module_name.to_s
          raise ArgumentError, "#{caller_engine} may not use the #{module_name} cache"
        end

        namespace = [ "rafelo", schema_version || Release.call, module_name, locale ].compact.join("/")
        namespace = "#{namespace}/viewer-#{viewer.id}/grants-#{grants_digest(grants)}" if scope == :viewer
        Rails.cache.fetch("#{namespace}/#{key}", expires_in: ttl) { yield }
      end

      def self.grants_digest(grants)
        Digest::SHA256.hexdigest(Array(grants).map(&:to_s).sort.join(","))
      end
    end
  end
end
