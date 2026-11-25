# frozen_string_literal: true

module Core
  class MetricsController < ApplicationController
    skip_before_action :load_session, :refresh_stale_grants, :require_viewer, only: :show
    before_action :skip_authorization
    skip_after_action :verify_authorized
    before_action :require_internal_network, only: :show
    throttle to: 12, within: 1.minute, only: :show, name: "core/metrics/ip"

    def show
      response.headers["Content-Type"] = "text/plain; version=0.0.4"
      render plain: Rafelo::Core::Metrics.text
    end

    private

    # OPS-04: a scrape endpoint for the internal network. A public client gets
    # the same answer as an unknown route, so the endpoint is not discoverable.
    # A forwarded address that does not resolve to a client (a malformed
    # X-Forwarded-For leaves the peer) fails closed.
    def require_internal_network
      head :not_found unless internal_request?
    end

    def internal_request?
      address = request.remote_ip.to_s
      return false if forwarded_from_peer?(address)

      Rafelo::Core::InternalNetwork.internal?(address)
    end

    def forwarded_from_peer?(address)
      return false if request.headers["X-Forwarded-For"].blank?

      address == request.remote_addr.to_s
    end
  end
end
