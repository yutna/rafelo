# frozen_string_literal: true

require "yaml"

module RuboCop
  module Cop
    module Rafelo
      # A migration table carries its engine's prefix (ARCH-03, ARCH-10).
      class EngineTablePrefix < Base
        MSG = "Rafelo/EngineTablePrefix: prefix a table created in engines/<engine>/db/migrate " \
              "with <engine>_ (ARCH-03); a recorded metadata.legacy_table_prefix is the only exception."
        RESTRICT_ON_SEND = %i[create_table create_join_table].freeze

        def on_send(node)
          table_node = node.arguments.first
          return unless table_node&.sym_type? || table_node&.str_type?

          engine = engine_from_path
          return unless engine

          table = table_node.value.to_s
          prefixes = [ engine, legacy_prefix(engine) ].compact
          return if prefixes.any? { |prefix| table.start_with?("#{prefix}_") }

          add_offense(table_node)
        end

        private

        def engine_from_path
          processed_source.file_path[%r{(?:\A|/)engines/([^/]+)/db/migrate/}, 1]
        end

        def legacy_prefix(engine)
          path = File.join(Dir.pwd, "engines", engine, "package.yml")
          return unless File.file?(path)

          metadata = YAML.safe_load_file(path, aliases: false)["metadata"]
          metadata["legacy_table_prefix"] if metadata.is_a?(Hash)
        rescue Psych::Exception
          nil
        end
      end
    end
  end
end
