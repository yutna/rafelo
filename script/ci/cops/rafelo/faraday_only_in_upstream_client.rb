# frozen_string_literal: true

module RuboCop
  module Cop
    module Rafelo
      class FaradayOnlyInUpstreamClient < Base
        MSG = "Use Rafelo::Core::UpstreamClient; only it may reference Faraday."

        def on_const(node)
          return unless node.const_name == "Faraday"
          return if processed_source.file_path.end_with?("upstream_client.rb")

          add_offense(node)
        end
      end
    end
  end
end
