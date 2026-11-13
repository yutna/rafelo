# frozen_string_literal: true

module Core
  class ReadyController < ApplicationController
    skip_before_action :load_session, :refresh_stale_grants, :require_viewer, only: :show
    before_action :skip_authorization
    skip_after_action :verify_authorized

    def show
      ActiveRecord::Base.connection.select_value("SELECT 1")
      head :ok
    end
  end
end
