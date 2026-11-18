# frozen_string_literal: true

module RuboCop
  module Cop
    module Rafelo
      # TLS verification stays on (BE-05, SEC-14).
      class NoTlsVerifyDisable < Base
        MSG = "Rafelo/NoTlsVerifyDisable: TLS verification must stay on (BE-05, SEC-14)."
        RESTRICT_ON_SEND = %i[verify_mode=].freeze

        def on_send(node)
          add_offense(node) if verify_none?(node.first_argument)
        end

        def on_pair(node)
          key = node.key
          return unless key.sym_type?

          add_offense(node) if key.value == :verify && node.value.false_type?
          add_offense(node) if key.value == :verify_mode && verify_none?(node.value)
        end

        private

        def verify_none?(node)
          node&.const_name.to_s.end_with?("VERIFY_NONE")
        end
      end
    end
  end
end
