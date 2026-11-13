# frozen_string_literal: true

module Rafelo
  module Core
    # Subclasses build the file content and call attach! inside the viewer
    # session; the row and blob are bound to that viewer (BE-18, BE-19).
    class ExportJob < ViewerJob
      def attach!(export, io:, filename:, content_type: "application/octet-stream")
        export.file.attach(io: io, filename: filename, content_type: content_type)
        export.update!(status: "ready", expires_at: Rails.application.config.x.exports.ttl_seconds.seconds.from_now)
      end
    end
  end
end
