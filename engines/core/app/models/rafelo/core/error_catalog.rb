# frozen_string_literal: true

require "yaml"

module Rafelo
  module Core
    module ErrorCatalog
      module_function

      def entries
        @entries ||= YAML.load_file(Rails.root.join("config", "errors.yml"))
      end

      def fetch(code)
        entries.fetch(code.to_s) do
          raise ArgumentError, "unknown error code: #{code}"
        end
      end
    end
  end
end
