# frozen_string_literal: true

module Core
  class MetricsController < ApplicationController
    skip_before_action :load_session, :refresh_stale_grants, :require_viewer, only: :show
    before_action :skip_authorization
    before_action :internal_only, only: :show
    skip_after_action :verify_authorized
    throttle to: 12, within: 1.minute, only: :show, name: "core/metrics/ip"

    def show
      response.headers["Content-Type"] = "text/plain; version=0.0.4"
      render plain: Rafelo::Core::Metrics.text
    end

    private

    # OPS-04/SEC-13: the scrape endpoint is for the internal network (a
    # sidecar or the platform's scraper), never the public edge. Answer 404 so
    # a public caller cannot tell the endpoint exists.
    def internal_only
      address = IPAddr.new(request.remote_ip)
      head :not_found unless address.loopback? || address.private?
    rescue IPAddr::InvalidAddressError
      head :not_found
    end
  end
end
