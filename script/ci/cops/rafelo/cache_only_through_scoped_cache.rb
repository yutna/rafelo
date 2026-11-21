# frozen_string_literal: true

module RuboCop
  module Cop
    module Rafelo
      # Cached data goes through the scoped cache (BE-17).
      class CacheOnlyThroughScopedCache < Base
        MSG = "Rafelo/CacheOnlyThroughScopedCache: use Rafelo::Core::ScopedCache; only it and specs may call Rails.cache (BE-17)."

        def on_send(node)
          names = Matching.receiver_names(node)
          return unless names[0] == "Rails" && (names.length == 1 ? Matching.method_name(node) == "cache" : names[1] == "cache")

          path = processed_source.file_path
          return if path.end_with?("/engines/core/app/models/rafelo/core/scoped_cache.rb")
          return if path.include?("/spec/") && !path.include?("/spec/enforcement/fixtures/")

          add_offense(node)
        end
      end
    end
  end
end
