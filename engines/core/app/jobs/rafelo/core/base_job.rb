# frozen_string_literal: true

module Rafelo
  module Core
    class BaseJob < ActiveJob::Base
      # Log lines carry the job class and the ids below, never the arguments.
      self.log_arguments = false

      # A job enqueued from a transaction must not run before the transaction
      # commits, or it can read a row that is rolled back (BE-11, BE-20).
      self.enqueue_after_transaction_commit = true

      attr_reader :rafelo_request_id, :rafelo_trace_id

      def initialize(*arguments)
        super
        @rafelo_request_id = Current.request_id
        @rafelo_trace_id = Current.trace_id.presence || SecureRandom.uuid
      end

      def serialize
        super.merge(
          "rafelo_request_id" => rafelo_request_id,
          "rafelo_trace_id" => rafelo_trace_id
        )
      end

      def deserialize(job_data)
        super
        @rafelo_request_id = job_data["rafelo_request_id"]
        @rafelo_trace_id = job_data["rafelo_trace_id"]
      end

      around_perform do |job, block|
        Current.set(request_id: job.rafelo_request_id, trace_id: job.rafelo_trace_id) do
          Rails.logger.tagged("job=#{job.class.name}", "request_id=#{job.rafelo_request_id}", "trace_id=#{job.rafelo_trace_id}") do
            block.call
          end
        end
      end
    end
  end
end
