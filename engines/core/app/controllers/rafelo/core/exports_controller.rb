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

        redirect_to main_app.core_export_file_path(signed_id: export.signed_download_id),
                    status: :see_other
      end
    end
  end
end
