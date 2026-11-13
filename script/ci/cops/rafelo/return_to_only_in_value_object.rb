# frozen_string_literal: true

module RuboCop
  module Cop
    module Rafelo
      class ReturnToOnlyInValueObject < Base
        MSG = "Read return_to only inside Rafelo::Core::ReturnTo."
        KEYS = %w[return_to returnTo].freeze

        def on_send(node)
          return unless node.method_name == :[]
          return unless node.receiver&.source.to_s.end_with?("params")
          key = node.arguments.first
          return unless key&.str_type? || key&.sym_type?
          return unless KEYS.include?(key.value.to_s)
          return if processed_source.file_path.end_with?("/engines/core/app/models/rafelo/core/return_to.rb")
          return if processed_source.file_path.include?("/spec/enforcement/fixtures/cops/legal/")

          add_offense(node)
        end
      end
    end
  end
end
