# frozen_string_literal: true

module Rafelo
  module Core
    # A job that acts for a viewer. Subclasses call `with_viewer_session` around
    # their work; the session id travels as a plain argument (BE-19).
    class ViewerJob < BaseJob
      class Stopped < StandardError
        attr_reader :reason

        def initialize(reason)
          @reason = reason.to_sym
          super("viewer job stopped: #{reason}")
        end
      end

      discard_on Stopped

      attr_reader :job_session, :job_budget, :job_token_provider

      private

      def with_viewer_session(session_id)
        session = Session.find_by(id: session_id)
        stop!(:revoked) unless session
        stop!(:expired) unless session.expires_at.future?

        @job_session = session
        @job_budget = CallBudget.job(
          deadline: RequestDeadline.new(Rails.application.config.x.jobs.upstream_deadline_seconds)
        )
        @job_token_provider = JobTokenProvider.new(
          session.id, budget: @job_budget, request_id: rafelo_request_id, trace_id: rafelo_trace_id
        )

        yield session
      ensure
        @job_session = nil
        @job_budget = nil
        @job_token_provider = nil
      end

      def stop!(reason)
        Rails.logger.info("job.stopped job=#{self.class.name} reason=#{reason}")
        raise Stopped.new(reason)
      end
    end
  end
end
