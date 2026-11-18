# frozen_string_literal: true

module Rafelo
  module Core
    class ViewerTokenProvider
      def initialize(session, request_id:, trace_id:, trace_sampled: false, budget: nil, deadline:, on_refresh: nil)
        @session = session
        @request_id = request_id
        @trace_id = trace_id
        @trace_sampled = trace_sampled
        @budget = budget
        @deadline = deadline
        @on_refresh = on_refresh
      end

      def token = @session.access_token
      def service? = false

      # Called by UpstreamClient after a 401. The local expiry may still look
      # fresh (a forced refresh), so this bypasses the freshness shortcut.
      def refresh!
        budget = @budget.respond_to?(:call) ? @budget.call : @budget
        budget ||= CallBudget.default(deadline: @deadline)
        SessionRefresher.new(
          session: @session,
          gateway: AuthGateway.new(
            budget: budget,
            request_id: @request_id,
            trace_id: @trace_id,
            trace_sampled: @trace_sampled
          ),
          timeout: Rails.application.config.x.sessions.refresh_timeout_seconds,
          wait: Rails.application.config.x.sessions.refresh_timeout_seconds + 2,
          force: true,
          deadline: @deadline
        ).call
        @session.reload
        @on_refresh&.call(@session)
        @session.access_token
      end
    end
  end
end
