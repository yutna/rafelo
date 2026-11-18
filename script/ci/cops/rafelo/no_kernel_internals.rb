# frozen_string_literal: true

module RuboCop
  module Cop
    module Rafelo
      # Kernel internals stay inside their kernel engine (ARCH-09).
      class NoKernelInternals < Base
        MSG = "Rafelo/NoKernelInternals: %<constant>s is kernel-internal; use the owning engine's public " \
              "surface (ARCH-09)."
        PREFIXES = {
          "Rafelo::Core::Internal" => %r{(?:\A|/)engines/core/},
          "Rafelo::DesignSystem::Internal" => %r{(?:\A|/)engines/design_system/}
        }.freeze

        def on_const(node)
          name = node.const_name
          PREFIXES.each do |prefix, owner|
            next unless name == prefix || name.start_with?("#{prefix}::")
            next if node.parent&.const_type? && node.parent.const_name.start_with?(prefix)
            next if processed_source.file_path.match?(owner)

            add_offense(node, message: format(MSG, constant: prefix))
          end
        end
      end
    end
  end
end
