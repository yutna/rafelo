# frozen_string_literal: true

require "json"
require "open3"

# One reader for the ESLint configuration the canaries prove. Both
# script/ci/eslint_canary and script/ci/enforcement_canaries resolve rules
# through `--print-config` here, so the two cannot drift (TS-07).
module Rafelo
  module ESLint
    RESTRICTIONS = %w[
      no-restricted-imports no-restricted-properties no-restricted-syntax
      react/forbid-elements @typescript-eslint/prefer-readonly
    ].freeze

    module_function

    def binary(root)
      File.join(root, "node_modules", ".bin", "eslint")
    end

    def print_config(root, path)
      output, stderr, status = Open3.capture3(binary(root), "--print-config", path, chdir: root)
      unless status.success?
        abort "eslint_canary: eslint --print-config failed for #{path}: #{stderr.strip}"
      end

      JSON.parse(output)
    rescue JSON::ParserError
      abort "eslint_canary: eslint --print-config returned invalid JSON for #{path}"
    end

    def active_rule_names(root, path)
      print_config(root, path).fetch("rules", {}).filter_map do |name, value|
        severity = value.is_a?(Array) ? value.first : value
        name if severity.is_a?(Integer) && severity.positive?
      end
    end

    # The local plugin's rules plus the restriction rules the canaries prove,
    # discovered at the real paths they apply to.
    def enforcement_rule_names(root, paths)
      paths.flat_map { |path| active_rule_names(root, path) }
           .select { |name| name.start_with?("rafelo/") || RESTRICTIONS.include?(name) }
           .uniq.sort
    end

    def local_rule_names(root, paths)
      paths.flat_map { |path| active_rule_names(root, path) }
           .select { |name| name.start_with?("rafelo/") }
           .uniq.sort
    end
  end
end
