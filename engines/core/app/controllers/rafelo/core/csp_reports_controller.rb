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
      # A browser CSP report carries no CSRF token (SEC-05): skip the token
      # callback for this one action only.
      skip_before_action :verify_authenticity_token, only: :create
      throttle to: 60, within: 1.minute, only: :create, name: "csp_reports/ip"

      # A browser report sink has no page to render; a throttled report gets an
      # empty 429 and the audit row from the throttle handler (BE-12, SEC-05).
      def render_throttled
        response.headers["Cache-Control"] = "no-store"
        head :too_many_requests
      end

      def create
        CspReport.from(request.raw_post).each do |report|
          log = report.to_log
          Metrics.csp_report(directive: log[:directive], blocked_origin: log[:blocked_origin])
          Rails.logger.info(log.to_json)
        end
        head :no_content
      rescue JSON::ParserError
        head :bad_request
      end
    end
  end
end
