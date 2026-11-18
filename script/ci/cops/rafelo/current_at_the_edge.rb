# frozen_string_literal: true

module RuboCop
  module Cop
    module Rafelo
      # Request state is read at the edge and passed down as arguments (BE-09).
      class CurrentAtTheEdge < Base
        MSG = "Rafelo/CurrentAtTheEdge: keep Current at the edge; pass request data as arguments."

        def on_send(node)
          receiver = node.receiver
          return unless receiver
          return unless %w[Current Rafelo::Core::Current].include?(receiver.const_name)
          return if edge_file?

          add_offense(node)
        end
        alias on_csend on_send

        private

        def edge_file?
          path = processed_source.file_path
          path.include?("/app/controllers/") ||
            path.include?("/app/middleware/") ||
            path.end_with?("/engines/core/lib/rafelo/core/log_payload.rb") ||
            path.end_with?("/engines/core/app/models/rafelo/core/log_payload.rb") ||
            path.end_with?("/engines/core/app/models/rafelo/core/error_reporter.rb") ||
            path.end_with?("/engines/core/app/jobs/rafelo/core/base_job.rb") ||
            path.end_with?("_middleware.rb")
        end
      end
    end
  end
end
