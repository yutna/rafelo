# frozen_string_literal: true

module RuboCop
  module Cop
    module Rafelo
      # Syntax-only matching for the custom cops (TS-07): every match is a node
      # pattern from here — constants and receivers through node patterns,
      # receiver chains unwrapped through both `send` and `csend`, and
      # `send`, `public_send` and `__send__` with a literal method name
      # counting as the call itself. No cop compares `node.source` or any
      # other source text.
      module Matching
        module_function

        # The name of a constant node; `::NAME` and `NAME` both return "NAME"
        # (the spec's pattern is `(const {nil? cbase} :NAME)`).
        def const_name(node)
          node&.const_name&.delete_prefix("::")
        end

        # The method name of a call.
        def method_name(node)
          return nil unless node&.send_type?

          name = node.method_name
          return name.to_s unless %i[send public_send __send__].include?(name)

          argument = node.arguments[0]
          return nil unless argument&.sym_type? || argument&.str_type?

          argument.value.to_s
        end

        # The receiver chain of a call, unwrapped through both `send` and
        # `csend`, as names from the outermost receiver to the innermost.
        def receiver_names(node)
          receiver = node&.receiver
          return [] unless receiver

          names = []
          while receiver.is_a?(RuboCop::AST::Node) && (receiver.send_type? || receiver.csend_type?)
            names << (Matching.method_name(receiver) || receiver.method_name.to_s)
            receiver = receiver.receiver
          end
          names << const_name(receiver) if receiver.is_a?(RuboCop::AST::Node) && receiver.const_type?
          names.reverse
        end
      end
    end
  end
end
