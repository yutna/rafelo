# frozen_string_literal: true

module RuboCop
  module Cop
    module Rafelo
      class NoTlsVerifyDisable < Base
        MSG = "TLS verification must stay on."

        def on_send(node)
          return unless node.method_name == :verify_mode=

          argument = node.first_argument
          return unless argument&.const_name.to_s.end_with?("VERIFY_NONE")

          add_offense(node)
        end
      end
    end
  end
end
