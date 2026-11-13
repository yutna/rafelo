# frozen_string_literal: true

module Core
  class MetricsController < ApplicationController
    skip_before_action :load_session, :refresh_stale_grants, :require_viewer, only: :show
    before_action :skip_authorization
    skip_after_action :verify_authorized

    def show
      response.headers["Content-Type"] = "text/plain; version=0.0.4"
      render plain: Rafelo::Core::Metrics.text
    end
  end
end
