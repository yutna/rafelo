# frozen_string_literal: true

module RuboCop
  module Cop
    module Rafelo
      # Concurrency primitives live behind the one executor (BE-16, TS-10).
      class ConcurrencyOnlyInExecutor < Base
        MSG = "Rafelo/ConcurrencyOnlyInExecutor: use Rafelo::Core::Executor; only it may reference Concurrent."

        def on_const(node)
          return unless node.const_name.start_with?("Concurrent::")
          return if executor_file? || spec_file?

          add_offense(node)
        end

        private

        def executor_file?
          processed_source.file_path.end_with?("/engines/core/app/models/rafelo/core/executor.rb")
        end

        def spec_file?
          processed_source.file_path.include?("/spec/") || processed_source.file_path.include?("/engines/") && processed_source.file_path.include?("/spec/")
        end
      end
    end
  end
end
