# frozen_string_literal: true

module RuboCop
  module Cop
    module Rafelo
      # Permission keys are generated constants (BE-03).
      class NoPermissionLiterals < Base
        MSG = "Rafelo/NoPermissionLiterals: pass a generated permission constant, not a string."

        def on_send(node)
          return unless %i[allows? capabilities].include?(node.method_name)

          node.arguments.each do |argument|
            add_offense(argument) if argument.str_type?
          end
        end
      end
    end
  end
end
