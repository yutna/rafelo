# frozen_string_literal: true

module Rafelo
  module Core
    class JobTokenProvider
      def initialize(session_id, budget:, request_id:, trace_id:)
        @session_id = session_id
        @budget = budget
        @request_id = request_id
        @trace_id = trace_id
      end

      def token
        refresh(force: false)
      end

      def refresh!
        refresh(force: true)
      end

      def service? = false

      private

      def refresh(force:)
        session = Session.readable_format.find_by(id: @session_id)
        raise ViewerJob::Stopped.new(:revoked) unless session
        raise ViewerJob::Stopped.new(:expired) unless session.expires_at.future?

        SessionRefresher.new(
          session: session,
          gateway: AuthGateway.new(
            budget: @budget,
            request_id: @request_id,
            trace_id: @trace_id
          ),
          timeout: Rails.application.config.x.sessions.refresh_timeout_seconds,
          wait: Rails.application.config.x.sessions.refresh_timeout_seconds + 2,
          force: force,
          deadline: @budget.deadline
        ).call
        session.reload.access_token
      rescue ApplicationError => error
        raise ViewerJob::Stopped.new(:expired) if error.code == "auth.expired"

        raise
      end
    end
  end
end
