# frozen_string_literal: true

module Rafelo
  module Core
    class PermissionSet
      SEGMENT = /\A[a-z][a-z0-9_]*\z/
      GRANT = /\A(?:\*|[a-z][a-z0-9_]*:(?:\*|[a-z][a-z0-9_]*:(?:\*|[a-z][a-z0-9_]*)))\z/

      def initialize(grants)
        @grants = grants.map(&:to_s).select { |grant| grant.match?(GRANT) }.freeze
      end

      def allows?(key)
        unless valid_key?(key)
          raise ArgumentError, "permission key must be <prefix>:<resource>:<action>: #{key.inspect}"
        end

        @grants.any? { |grant| matches?(grant, key) }
      end

      def reads_any?(prefixes)
        prefixes.any? do |prefix|
          @grants.any? do |grant|
            grant == "*" ||
              (grant.start_with?("#{prefix}:") && (grant.end_with?(":read") || grant.end_with?(":*")))
          end
        end
      end

      private

      def valid_key?(key)
        parts = key.to_s.split(":")
        parts.length == 3 && parts.all? { |part| part.match?(SEGMENT) }
      end

      def matches?(grant, key)
        return true if grant == "*"
        return true if grant.end_with?(":*") && key.start_with?(grant.delete_suffix("*"))

        grant == key
      end
    end
  end
end
