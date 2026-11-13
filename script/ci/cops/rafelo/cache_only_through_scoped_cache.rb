# frozen_string_literal: true

module RuboCop
  module Cop
    module Rafelo
      class CacheOnlyThroughScopedCache < Base
        MSG = "Use Rafelo::Core::ScopedCache; only it and config/specs may call Rails.cache."

        def on_send(node)
          return unless node.source.start_with?("Rails.cache")
          path = processed_source.file_path
          return if path.end_with?("scoped_cache.rb") || path.include?("/config/")
          return if path.include?("/spec/") && !path.include?("/spec/enforcement/fixtures/")

          add_offense(node)
        end
      end
    end
  end
end
