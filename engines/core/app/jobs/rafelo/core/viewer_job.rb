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

      private

      def with_viewer_session(session_id)
        session = Session.find_by(id: session_id)
        stop!(:revoked) unless session
        stop!(:expired) unless session.expires_at.future?

        Current.session = session
        Current.viewer = session.viewer
        Current.permissions = session.permission_set
        Current.call_budget = CallBudget.new(
          api: 10,
          deadline: RequestDeadline.new(Rails.application.config.x.jobs.upstream_deadline_seconds)
        )
        Current.token_provider = JobTokenProvider.new(session.id, budget: Current.call_budget)

        yield session
      ensure
        Current.reset
      end

      def stop!(reason)
        Rails.logger.info("job.stopped job=#{self.class.name} reason=#{reason}")
        raise Stopped.new(reason)
      end
    end
  end
end
