# frozen_string_literal: true

module RuboCop
  module Cop
    module Rafelo
      # A skipped assertion names the issue that owns it (TS-05).
      class SkipNeedsIssue < Base
        MSG = "Rafelo/SkipNeedsIssue: add #<issue> or an issue URL on the same line (TS-05)."
        SKIP_METHODS = %i[skip pending xit xspecify xexample xdescribe xcontext].freeze
        EXAMPLE_METHODS = %i[it specify example].freeze
        SKIP_METADATA = %i[skip pending].freeze
        RESTRICT_ON_SEND = (SKIP_METHODS + EXAMPLE_METHODS + [ :pause ]).freeze

        def on_send(node)
          if node.method_name == :pause
            return unless node.receiver&.source == "Prosopite"
            return if enforcement_path?

            add_offense(node.loc.selector) unless issue_marker?(node.loc.line)
            return
          end

          if EXAMPLE_METHODS.include?(node.method_name)
            node.arguments.each do |argument|
              next unless argument.sym_type? && argument.value == :skip

              add_offense(argument) unless issue_marker?(argument.loc.line)
            end
            return
          end

          add_offense(node.loc.selector) unless issue_marker?(node.loc.line)
        end

        def on_pair(node)
          key = node.key
          return unless key.sym_type?

          if SKIP_METADATA.include?(key.value)
            add_offense(node) unless issue_marker?(node.loc.line)
          elsif key.value == :prosopite && node.value.false_type? && !enforcement_path?
            add_offense(node) unless issue_marker?(node.loc.line)
          end
        end

        private

        def enforcement_path?
          processed_source.file_path.include?("spec/enforcement/")
        end

        def issue_marker?(line)
          comment = processed_source.comments.find { |entry| entry.loc.line == line }
          return false unless comment

          comment.text.match?(/#\d+/) || comment.text.match?(%r{https?://\S+/issues/\d+})
        end
      end
    end
  end
end
