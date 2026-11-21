# frozen_string_literal: true

module RuboCop
  module Cop
    module Rafelo
      class ConfigXOnlyInCore < Base
        MSG = "Rafelo/ConfigXOnlyInCore: read config.x only in engines/core; pass configuration through config/ or a typed setting (ARCH-01, ARCH-10, BE-08)."

        def on_send(node)
          return unless Matching.method_name(node) == "x"
          return unless Matching.receiver_names(node).include?("config")
          return if processed_source.file_path.include?("/engines/core/")
          return if processed_source.file_path.include?("/spec/") && !processed_source.file_path.include?("/spec/enforcement/fixtures/")

          add_offense(node)
        end
      end
    end
  end
end
