# frozen_string_literal: true

module Rafelo
  module Core
    # The base for every page's props object. A subclass builds the page's
    # envelope through #envelope; the base rejects any missing or extra
    # top-level key so a page cannot shadow a shared prop (CT-01).
    class PageProps
      ENVELOPE_KEYS = %i[data meta query pagination can].freeze

      class << self
        def policy_class(policy = nil)
          @policy_class = policy if policy
          @policy_class || raise(ArgumentError, "#{name} declares no policy class")
        end

        def capability(permission_key, policy_method, flag: nil)
          declarations[permission_key.to_s] = CapabilityMap::Entry.new(
            key: permission_key.to_s,
            policy_method: policy_method,
            flag: flag
          )
        end

        def declarations
          @declarations ||= {}
        end
      end

      attr_reader :context

      def initialize(context:)
        @context = context
      end

      def to_inertia
        payload = envelope
        validate_envelope!(payload)
        payload
      end

      def capabilities(*permission_keys)
        entries = permission_keys.map do |permission_key|
          self.class.declarations.fetch(permission_key.to_s) do
            raise ArgumentError, "#{self.class.name} declares no capability #{permission_key}"
          end
        end

        CapabilityMap.new(
          policy: self.class.policy_class.new(
            context.viewer,
            permissions: context.permissions || PermissionSet.new([])
          ),
          entries: entries,
          flags: context.flags
        ).to_h
      end

      private

      def envelope
        raise NotImplementedError, "#{self.class.name} must implement #envelope"
      end

      def validate_envelope!(envelope)
        keys = envelope.keys.map(&:to_sym)
        missing = ENVELOPE_KEYS - keys
        extra = keys - ENVELOPE_KEYS
        return if missing.empty? && extra.empty?

        raise ArgumentError, "invalid page envelope: missing=#{missing.inspect} extra=#{extra.inspect}"
      end
    end
  end
end
