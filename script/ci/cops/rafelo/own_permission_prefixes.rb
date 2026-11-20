# frozen_string_literal: true

module RuboCop
  module Cop
    module Rafelo
      # A module authorizes only with its own declared permission prefixes (BE-03).
      class OwnPermissionPrefixes < Base
        MSG = "Rafelo/OwnPermissionPrefixes: %<prefixes>s is outside this module's permission_prefixes (BE-03); " \
              "another module's keys may inform a page, never authorize this module's actions."
        RESTRICT_ON_SEND = %i[register].freeze

        def on_send(node)
          return unless Matching.receiver_names(node).first == "Rafelo::Core::Modules"

          hash = node.arguments.find(&:hash_type?)
          return unless hash

          key = pair_value(hash, :key)
          declared = declared_prefixes(hash, key)
          unexpected = manifest_prefixes - declared
          return if unexpected.empty?

          add_offense(declared_node(hash) || node,
                      message: format(MSG, prefixes: unexpected.join(", ")))
        end

        private

        def pair_value(hash, name)
          hash.pairs.find { |pair| pair.key.sym_type? && pair.key.value == name }&.value
        end

        def declared_node(hash)
          pair_value(hash, :permission_prefixes)
        end

        def declared_prefixes(hash, key)
          node = declared_node(hash)
          return node.values.map { |value| value.value.to_s } if node&.array_type?

          value = key&.value
          value.nil? ? [] : [ value.to_s ]
        end

        def manifest_prefixes
          engine = processed_source.file_path[%r{(?:\A|/)engines/([^/]+)/config/module\.rb\z}, 1]
          return [] unless engine

          path = File.join(Dir.pwd, "engines", engine, "config", "permissions.yml")
          return [] unless File.file?(path)

          YAML.safe_load_file(path, aliases: false).keys
        rescue Psych::Exception
          []
        end
      end
    end
  end
end
