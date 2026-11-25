# frozen_string_literal: true

require "action_controller/log_subscriber"

# Why: Rails logs the full redirect location, and an export redirect carries a
# short-lived signed URL, a bearer credential (BE-18). The kernel serves it at
# /core/exports/; an adopted app's older Active Storage redirect is redacted too.
# Upstream: https://github.com/rails/rails
module Rafelo
  module RedactStorageRedirects
    REDACTED_PREFIXES = [ "/rails/active_storage/", "/core/exports/" ].freeze

    def redirect_to(event)
      location = event.payload[:location].to_s
      return if REDACTED_PREFIXES.any? { |prefix| location.include?(prefix) }

      super
    end
  end
end

ActionController::LogSubscriber.prepend(Rafelo::RedactStorageRedirects)
