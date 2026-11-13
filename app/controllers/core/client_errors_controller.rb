# frozen_string_literal: true

module Core
  class ClientErrorsController < ApplicationController
    before_action :skip_authorization
    throttle to: 30, within: 1.minute, only: :create, name: "client_errors/ip"
    skip_after_action :verify_authorized

    def create
      head :no_content
    end
  end
end
