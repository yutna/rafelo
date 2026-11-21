# frozen_string_literal: true

module RuboCop
  module Cop
    module Rafelo
      # The factory is the only PageContext constructor (BE-01).
      class PageContextThroughFactory < Base
        MSG = "Rafelo/PageContextThroughFactory: build PageContext through PageContextFactory."

        def on_send(node)
          names = Matching.receiver_names(node)
          return unless names.first&.end_with?("PageContext")
          return unless node.method_name == :new || node.method_name == :[]
          return if processed_source.file_path.include?("/engines/core/")

          add_offense(node)
        end
      end
    end
  end
end
