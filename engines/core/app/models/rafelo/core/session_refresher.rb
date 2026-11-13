# frozen_string_literal: true

module Rafelo
  module Core
    class SessionRefresher
      def initialize(session:, gateway:, timeout:, wait: 10.0)
        @session = session
        @gateway = gateway
        @timeout = timeout
        @wait = wait
      end

      def call
        return @session.access_token if fresh? && !@session.grants_stale?

        version = @session.claim_refresh!(timeout: @timeout)
        if version
          refresh_winner(version)
        else
          wait_for_winner
        end
      end

      private

      def fresh?
        @session.access_expires_at && @session.access_expires_at > 60.seconds.from_now
      end

      def refresh_winner(version)
        result = @gateway.refresh(refresh_token: @session.refresh_token)
        @session.complete_refresh!(
          version: version,
          access_token: result.access_token,
          refresh_token: result.refresh_token,
          access_expires_at: result.access_expires_at,
          grants: result.grants
        )
        result.access_token
      rescue ActiveRecord::RecordNotFound
        raise ApplicationError.new("auth.expired")
      rescue StandardError
        @session.fail_refresh!(version: version)
        raise
      end

      def wait_for_winner
        deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + @wait
        original = @session.access_token
        loop do
          begin
            @session.reload
          rescue ActiveRecord::RecordNotFound
            raise ApplicationError.new("auth.expired")
          end

          return @session.access_token if @session.access_token != original
          raise ApplicationError.new("upstream.unavailable") if @session.refreshing_since.nil?
          raise ApplicationError.new("upstream.unavailable") if Process.clock_gettime(Process::CLOCK_MONOTONIC) >= deadline

          sleep 0.05
        end
      end
    end
  end
end
