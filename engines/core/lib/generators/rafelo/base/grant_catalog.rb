# frozen_string_literal: true

require "json"
require "pathname"
require "yaml"

module Rafelo
  module Generators
    # Keeps the fake upstream's grant catalog in step with the module manifests
    # a generator writes (BE-03). The drift spec compares the two, so a new
    # module or page must add its keys here or the generated slice fails
    # `bin/ci` before anyone can learn from it.
    module GrantCatalog
      module_function

      # Rebuilds the keys of every prefix a manifest declares, so a removed or
      # renamed permission cannot leave a stale grant. Grants under any other
      # prefix belong to the app (kernel fixtures, synthetic test keys) and are
      # kept untouched.
      def sync(root)
        root = Pathname(root)
        path = root.join("config/grants.json")
        return unless path.file?

        grants = JSON.parse(path.read).fetch("grants")
        generated = manifest_keys(root).uniq.sort
        owned = generated.map { |key| key.split(":").first }.uniq
        rebuilt = (grants.reject { |grant| owned.include?(grant.split(":").first) } + generated).uniq.sort
        return if rebuilt == grants

        path.write(JSON.pretty_generate("grants" => rebuilt) + "\n")
      end

      def manifest_keys(root)
        Dir[root.join("engines/*/config/permissions.yml")].flat_map do |manifest_path|
          manifest = YAML.safe_load_file(manifest_path, aliases: false) || {}
          manifest.flat_map do |prefix, resources|
            (resources || {}).flat_map do |resource, actions|
              Array(actions).map { |action| "#{prefix}:#{resource}:#{action}" }
            end
          end
        end
      end
    end
  end
end
