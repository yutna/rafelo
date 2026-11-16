# frozen_string_literal: true

module Rafelo
  module Core
    class CspReportsController < BaseController
      # A browser sends a CSP report without a session or a CSRF token. This is
      # the only action that skips forgery protection (SEC-05). The body cap is
      # a core Rack middleware before Rails parses it (BE-12).
      skip_before_action :load_session, :refresh_stale_grants, :require_viewer, only: :create
      before_action :skip_authorization
      skip_after_action :verify_authorized
      # A browser CSP report carries no CSRF token (SEC-05).
      skip_forgery_protection only: :create # codeql[rb/csrf-protection-disabled]
      throttle to: 60, within: 1.minute, only: :create, name: "csp_reports/ip"

      def create
        CspReport.from(request.raw_post).each do |report|
          Rails.logger.info(report.to_log.to_json)
        end
        head :no_content
      rescue JSON::ParserError
        head :bad_request
      end
    end
  end
end
