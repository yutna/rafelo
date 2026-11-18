# frozen_string_literal: true

module RuboCop
  module Cop
    module Rafelo
      # Streaming belongs to the download controller (BE-18).
      class SendStreamOnlyInDownloads < Base
        MSG = "Rafelo/SendStreamOnlyInDownloads: send_stream only in Rafelo::Core::DownloadController."

        def on_send(node)
          return unless node.method_name == :send_stream
          return if processed_source.file_path.end_with?("/engines/core/app/controllers/rafelo/core/download_controller.rb")

          add_offense(node)
        end
      end
    end
  end
end
