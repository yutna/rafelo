# frozen_string_literal: true

module Core
  class ClientErrorsController < ApplicationController
    skip_before_action :load_session, :refresh_stale_grants, :require_viewer, only: :create
    before_action :skip_authorization
    throttle to: 30, within: 1.minute, only: :create, name: "client_errors/ip"
    skip_after_action :verify_authorized

    def create
      head :no_content
    end
  end
end
