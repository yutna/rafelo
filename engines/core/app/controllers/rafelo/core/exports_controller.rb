# frozen_string_literal: true

module Rafelo
  module Core
    class ExportsController < BaseController
      layout "application"

      skip_after_action :verify_authorized

      def show
        export = Export.find_by(id: params[:id])
        raise ApplicationError.new("resource.not_found") unless export && export.viewer_id == Current.viewer&.id.to_s
        raise ApplicationError.new("resource.not_found") unless export.file.attached?

        redirect_to rails_blob_url(
          export.file,
          expires_in: 5.minutes,
          disposition: :attachment
        ), status: :see_other
        AuditRecorder.record(controller: self, event: "export_download", outcome: "success", target: export.id)
      end
    end
  end
end
