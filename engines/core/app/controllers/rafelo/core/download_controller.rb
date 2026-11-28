# frozen_string_literal: true

module Rafelo
  module Core
    # The only code that calls send_stream (BE-18). A source is a callable that
    # yields body chunks; the controller waits for the first chunk, so an
    # upstream status or size failure answers the error page before headers.
    class DownloadController < BaseController
      include ActionController::Live

      layout "application"

      # The producer throws this out of the upstream call when a viewer stops
      # draining the queue. A throw, unlike an exception, is not seen by the
      # client's breaker: a stalled viewer is neither a failure nor a success
      # (BE-05, BE-16, BE-18).
      DOWNLOAD_STALLED = :rafelo_download_stalled

      # A source that finishes without a chunk is a legitimate empty file: the
      # producer's :done arrives before any :chunk, and the stream must end
      # without waiting for the deadline (BE-18).
      DOWNLOAD_EMPTY = :rafelo_download_empty

      def send_download(filename:, source:, type: nil, max_bytes: nil, event: "download")
        authorize_download!
        permit = DownloadLimiter.acquire
        raise ApplicationError.new("upstream.unavailable") unless permit

        queue = SizedQueue.new(8)
        deadline = request_deadline
        context = Current.attributes
        producer = Thread.new do
          Current.set(**context) do
            stalled = catch(DOWNLOAD_STALLED) do
              source.call do |chunk|
                throw DOWNLOAD_STALLED, true unless enqueue(queue, deadline, [ :chunk, chunk ])
              end
              enqueue(queue, deadline, [ :done ])
              false
            end
            deliver_error(queue, deadline, DownloadStalled.new) if stalled
          end
        rescue StandardError => error
          deliver_error(queue, deadline, error)
        end
        first = wait_for_first_chunk(queue, deadline)
        limit = max_bytes || Rails.application.config.x.downloads.max_bytes
        written = 0

        response.headers["Cache-Control"] = "no-store"
        response.headers["X-Content-Type-Options"] = "nosniff"
        send_stream(filename: sanitized_filename(filename), type: type) do |stream|
          unless first == DOWNLOAD_EMPTY
            written += first.bytesize
            raise ApplicationError.new("unexpected", "Download exceeded #{limit} bytes") if written > limit

            stream.write(first)
            loop do
              kind, value = dequeue(queue, deadline)
              break if kind == :done
              raise value if kind == :error

              written += value.bytesize
              raise ApplicationError.new("unexpected", "Download exceeded #{limit} bytes") if written > limit

              stream.write(value)
            end
          end
        end
        AuditRecorder.record(controller: self, event: event, outcome: "success", target: filename)
      rescue StandardError
        AuditRecorder.record(controller: self, event: event, outcome: "failure", target: filename)
        raise
      ensure
        producer&.kill
        DownloadLimiter.release(permit)
      end

      private

      def authorize_download!
        return if pundit_policy_authorized?

        raise ApplicationError.new("unexpected", "authorize before send_download")
      end

      def wait_for_first_chunk(queue, deadline)
        loop do
          kind, value = dequeue(queue, deadline)
          return value if kind == :chunk
          return DOWNLOAD_EMPTY if kind == :done
          raise value if kind == :error
        end
      end

      # A slow client stops the consumer inside stream.write; the producer must
      # not hold a pooled upstream connection past the request deadline waiting
      # for room (BE-16, BE-18). Returns false on the deadline; the caller
      # throws out of the upstream call so the breaker records no outcome.
      def enqueue(queue, deadline, message)
        remaining = deadline.remaining
        return false if remaining.zero?

        !queue.push(message, timeout: remaining).nil?
      end

      # The error handoff is best effort: a full queue means the consumer is
      # past the deadline anyway, and its own bounded dequeue reports the
      # timeout.
      def deliver_error(queue, deadline, error)
        queue.push([ :error, error ], true)
      rescue ThreadError
        remaining = deadline.remaining
        return if remaining.zero?

        begin
          queue.push([ :error, error ], timeout: remaining)
        rescue ThreadError
          nil
        end
      end

      def dequeue(queue, deadline)
        remaining = deadline.remaining
        raise DownloadStalled.new if remaining.zero?

        message = queue.pop(timeout: remaining)
        raise DownloadStalled.new if message.nil?

        message
      end

      def sanitized_filename(filename)
        File.basename(filename.to_s).gsub(/[^0-9A-Za-z._-]/, "_").presence || "download"
      end
    end
  end
end
