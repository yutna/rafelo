# frozen_string_literal: true

module RuboCop
  module Cop
    module Rafelo
      # Faraday belongs to the one named client (ARCH-01, ARCH-02, BE-05, SEC-14).
      class FaradayOnlyInUpstreamClient < Base
        MSG = "Rafelo/FaradayOnlyInUpstreamClient: use Rafelo::Core::UpstreamClient; only it may reference Faraday (ARCH-01)."

        def on_const(node)
          return unless node.const_name == "Faraday"
          return if processed_source.file_path.end_with?("/engines/core/app/models/rafelo/core/upstream_client.rb")

          add_offense(node)
        end
      end
    end
  end
end
