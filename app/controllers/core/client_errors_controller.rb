# frozen_string_literal: true

module Core
  class ClientErrorsController < ApplicationController
    skip_before_action :load_session, :refresh_stale_grants, :require_viewer, only: :create
    before_action :skip_authorization
    throttle to: 30, within: 1.minute, only: :create, name: "client_errors/ip"
    throttle to: 10, within: 1.minute, only: :create, name: "client_errors/session",
             by: -> {
               token = cookies[session_cookie_name]
               token.present? ? Digest::SHA256.hexdigest(token) : request.remote_ip
             }
    skip_after_action :verify_authorized

    def create
      payload = JSON.parse(request.raw_post.presence || "{}")
      return head :bad_request unless payload.is_a?(Hash)

      report = Rafelo::Core::ClientErrorReport.from(payload)
      Rails.error.report(report.error, handled: true, severity: :error, context: report.to_h)
      head :no_content
    rescue JSON::ParserError
      head :bad_request
    end
  end
end
