# frozen_string_literal: true

module Rafelo
  module Core
    class ExportsController < DownloadController
      throttle to: 30, within: 1.minute, only: :show, name: "export/ip"

      def show
        export = Export.readable_format.find_by(id: params[:id])
        raise ApplicationError.new("resource.not_found") unless export

        authorize export, :show?, policy_class: Rafelo::Core::ExportPolicy
        raise ApplicationError.new("resource.not_found") unless export.file.attached?

        send_download(
          filename: export.filename,
          type: export.file.content_type,
          source: ->(&block) do
            export.file.blob.open do |file|
              while (chunk = file.read(64 * 1024))
                block.call(chunk)
              end
            end
          end,
          event: "export"
        )
      end
    end
  end
end
