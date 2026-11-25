# frozen_string_literal: true

module Rafelo
  module Core
    # Serves the short-lived signed URL an authorized export click redirects
    # to (BE-18). The signed id is the bearer credential, so this endpoint
    # reads no session and streams the attachment through the download
    # controller, which enforces the size cap and records the audit event.
    class ExportFilesController < DownloadController
      skip_before_action :load_session, :refresh_stale_grants, :require_viewer, only: :show
      before_action :skip_authorization
      throttle to: 60, within: 1.minute, only: :show, name: "export/file/ip"

      def show
        export = Export.find_by_signed_download_id(params[:signed_id])
        raise ApplicationError.new("resource.not_found") unless export&.file&.attached?

        authorize export, :show?, policy_class: ExportFilePolicy
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
