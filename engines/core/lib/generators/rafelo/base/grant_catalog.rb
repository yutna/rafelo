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

      # Rebuilds the generated keys from every manifest and keeps the grants the
      # app owns itself. The catalog records which keys came from a manifest in
      # "generated", so a removed or renamed permission cannot leave a stale
      # grant behind. A catalog written before the marker existed is treated as
      # all fixture; the first sync records the marker without dropping a key.
      def sync(root)
        root = Pathname(root)
        path = root.join("config/grants.json")
        return unless path.file?

        catalog = JSON.parse(path.read)
        grants = Array(catalog.fetch("grants"))
        generated_before = Array(catalog["generated"])
        fixture = grants - generated_before
        generated = manifest_keys(root).uniq.sort
        rebuilt = (fixture + generated).uniq.sort
        return if rebuilt == grants && generated == generated_before

        path.write(JSON.pretty_generate("grants" => rebuilt, "generated" => generated) + "\n")
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
