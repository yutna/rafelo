# frozen_string_literal: true

module RuboCop
  module Cop
    module Rafelo
      class ConfigXOnlyInCore < Base
        MSG = "Read config.x only in core."

        def on_send(node)
          return unless node.method_name == :x
          return unless node.receiver&.source.to_s.include?("config")
          return if processed_source.file_path.include?("/engines/core/")
          return if processed_source.file_path.include?("/spec/") && !processed_source.file_path.include?("/spec/enforcement/fixtures/")

          add_offense(node)
        end
      end
    end
  end
end
