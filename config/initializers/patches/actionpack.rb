# frozen_string_literal: true

require "action_controller/log_subscriber"

# Why: Rails logs the full redirect location, and an export redirect carries a
# short-lived signed Active Storage URL, a bearer credential (BE-18).
# Upstream: https://github.com/rails/rails
module Rafelo
  module RedactStorageRedirects
    def redirect_to(event)
      return if event.payload[:location].to_s.include?("/rails/active_storage/")

      super
    end
  end
end

ActionController::LogSubscriber.prepend(Rafelo::RedactStorageRedirects)
