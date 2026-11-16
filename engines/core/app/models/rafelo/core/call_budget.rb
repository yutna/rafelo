# frozen_string_literal: true

module Rafelo
  module Core
    class CallBudget
      attr_accessor :deadline

      def self.default(deadline: nil)
        budgets = Rails.application.config.x.budgets
        new(budgets.upstream_calls, deadline: deadline, refresh_limits: budgets.refresh_calls)
      end

      def self.job(deadline:)
        budgets = Rails.application.config.x.budgets
        new(budgets.job_calls, deadline: deadline, refresh_limits: budgets.refresh_calls)
      end

      def initialize(limits = {}, deadline: nil, refresh_limits: nil, **extra)
        @limits = limits.merge(extra).transform_keys(&:to_sym)
        @refresh_limits = (refresh_limits || @limits).transform_keys(&:to_sym)
        @counts = Hash.new(0)
        @refresh_counts = Hash.new(0)
        @mutex = Mutex.new
        @deadline = deadline
      end

      def consume!(upstream, kind: :page)
        enforce_deadline!
        name = upstream.to_sym
        if kind == :page
          limit = @limits.fetch(name) { raise ArgumentError, "no call budget for upstream #{name}" }
          counts = @counts
        else
          limit = @refresh_limits.fetch(name, 1)
          counts = @refresh_counts
        end
        @mutex.synchronize do
          raise ApplicationError.new("request.throttled") if counts[name] >= limit

          counts[name] += 1
        end
      end

      def count(upstream, kind: :page)
        counts = kind == :page ? @counts : @refresh_counts
        @mutex.synchronize { counts[upstream.to_sym] }
      end

      def remaining
        return unless @deadline
        return @deadline.remaining if @deadline.respond_to?(:remaining)

        [ @deadline - Process.clock_gettime(Process::CLOCK_MONOTONIC), 0 ].max
      end

      def expired?
        return false unless @deadline
        return @deadline.expired? if @deadline.respond_to?(:expired?)

        remaining <= 0
      end

      private

      def enforce_deadline!
        raise ApplicationError.new("upstream.timeout") if expired?
      end
    end
  end
end
