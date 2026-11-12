# frozen_string_literal: true

module Rafelo
  module Core
    # Builds the `can` map from a policy and the capability declaration that
    # names the policy method each key mirrors. The page schema (CT-01) lists
    # the same keys, so the two cannot drift silently.
    class CapabilityMap
      Entry = Data.define(:key, :policy_method, :flag)

      def initialize(policy:, entries:, flags: {})
        @policy = policy
        @entries = entries
        @flags = flags
      end

      def to_h
        @entries.to_h do |entry|
          allowed = allowed?(entry)
          [ key_for(entry.key), { allowed: allowed, reason: allowed ? nil : reason(entry) } ]
        end
      end

      private

      def allowed?(entry)
        return false if entry.flag && !@flags[entry.flag.to_sym]

        @policy.public_send(entry.policy_method)
      end

      def key_for(permission_key)
        permission_key.split(":")[1..].join(".")
      end

      def reason(entry)
        return "disabled" if entry.flag

        "forbidden"
      end
    end
  end
end
