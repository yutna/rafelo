# frozen_string_literal: true

module Rafelo
  module Core
    class ExportsController < DownloadController
      throttle to: 30, within: 1.minute, only: :show, name: "export/ip"

      def show
        authorize :export, :show?, policy_class: Rafelo::Core::ExportPolicy
        export = Export.find_by(id: params[:id])
        raise ApplicationError.new("resource.not_found") unless export && export.viewer_id == Current.viewer&.id.to_s
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
          end
        )
      end
    end
  end
end
