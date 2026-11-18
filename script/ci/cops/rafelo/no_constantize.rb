# frozen_string_literal: true

module RuboCop
  module Cop
    module Rafelo
      # A dynamic constant lookup hides a dependency from Packwerk (ARCH-10).
      class NoConstantize < Base
        MSG = "Rafelo/NoConstantize: a dynamic constant lookup hides a dependency from Packwerk " \
              "(ARCH-10). Reference the constant through the owning engine's app/public/ and declare the dependency."
        RESTRICT_ON_SEND = %i[constantize safe_constantize const_get].freeze

        def_node_matcher :string_class_name?, "(pair (sym :class_name) (str _))"

        def on_send(node) = add_offense(node.loc.selector)

        def on_pair(node)
          add_offense(node) if string_class_name?(node)
        end
      end
    end
  end
end
