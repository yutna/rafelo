# frozen_string_literal: true

module Rafelo
  module Core
    class ViewerTokenProvider
      def initialize(session)
        @session = session
      end

      def token = @session.access_token
      def service? = false

      # Called by UpstreamClient after a 401. The local expiry may still look
      # fresh (a forced refresh), so this bypasses the freshness shortcut.
      def refresh!
        budget = Current.call_budget || CallBudget.default
        SessionRefresher.new(
          session: @session,
          gateway: AuthGateway.new(
            budget: budget,
            request_id: Current.request_id,
            trace_id: Current.trace_id
          ),
          timeout: Rails.application.config.x.sessions.refresh_timeout_seconds,
          wait: Rails.application.config.x.sessions.refresh_timeout_seconds + 2,
          force: true,
          deadline: budget.deadline
        ).call
        @session.reload
        Current.permissions = @session.permission_set if Current.session&.id == @session.id
        @session.access_token
      end
    end
  end
end
