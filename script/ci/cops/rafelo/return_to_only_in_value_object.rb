# frozen_string_literal: true

module RuboCop
  module Cop
    module Rafelo
      # return_to is read only by its value object (SEC-11).
      class ReturnToOnlyInValueObject < Base
        MSG = "Rafelo/ReturnToOnlyInValueObject: read return_to only inside Rafelo::Core::ReturnTo (SEC-11)."
        KEYS = %w[return_to returnTo].freeze
        RESTRICT_ON_SEND = %i[[] fetch dig].freeze

        def on_send(node)
          return unless Matching.receiver_names(node).last == "params"

          keys = node.arguments.select { |argument| argument.str_type? || argument.sym_type? }
          return unless keys.any? { |key| KEYS.include?(key.value.to_s) }
          return if processed_source.file_path.end_with?("/engines/core/app/models/rafelo/core/return_to.rb")

          add_offense(node)
        end
      end
    end
  end
end
