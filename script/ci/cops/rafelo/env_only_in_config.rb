# frozen_string_literal: true

module RuboCop
  module Cop
    module Rafelo
      # ENV and Rails credentials are read at one configuration boundary
      # (ARCH-01, BE-04, BE-08).
      class EnvOnlyInConfig < Base
        MSG = "Rafelo/EnvOnlyInConfig: read ENV and Rails credentials only in config/."

        def on_send(node)
          return unless env_read?(node) || credentials_read?(node)

          add_offense(node)
        end
        alias on_csend on_send

        private

        def env_read?(node)
          return false unless node.send_type? || node.csend_type?

          # Every ENV access is a configuration read: [], fetch, key?, to_h,
          # slice, []= and the rest (BE-08, TS-07).
          Matching.receiver_names(node) == [ "ENV" ]
        end

        def credentials_read?(node)
          return false unless node.send_type? || node.csend_type?
          return false unless node.method_name.to_s == "credentials"

          Matching.receiver_names(node) == [ "Rails", "application" ]
        end
      end
    end
  end
end
