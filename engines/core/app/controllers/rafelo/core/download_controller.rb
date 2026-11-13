# frozen_string_literal: true

module Rafelo
  module Core
    # The only code that calls send_stream (BE-18). A source is a callable that
    # yields body chunks; the controller waits for the first chunk, so an
    # upstream status or size failure answers the error page before headers.
    class DownloadController < BaseController
      include ActionController::Live

      layout "application"

      def send_download(filename:, source:, type: nil, max_bytes: nil)
        authorize_download!
        permit = DownloadLimiter.acquire
        raise ApplicationError.new("upstream.unavailable") unless permit

        queue = Queue.new
        producer = Thread.new do
          source.call { |chunk| queue << [ :chunk, chunk ] }
          queue << [ :done ]
        rescue StandardError => error
          queue << [ :error, error ]
        end
        first = wait_for_first_chunk(queue)
        limit = max_bytes || Rails.application.config.x.downloads.max_bytes
        written = 0

        response.headers["Cache-Control"] = "no-store"
        response.headers["X-Content-Type-Options"] = "nosniff"
        send_stream(filename: sanitized_filename(filename), type: type) do |stream|
          if first
            written += first.bytesize
            raise ApplicationError.new("unexpected", "Download exceeded #{limit} bytes") if written > limit

            stream.write(first)
          end
          loop do
            kind, value = queue.pop
            break if kind == :done
            raise value if kind == :error

            written += value.bytesize
            raise ApplicationError.new("unexpected", "Download exceeded #{limit} bytes") if written > limit

            stream.write(value)
          end
        end
      ensure
        producer&.kill
        DownloadLimiter.release(permit)
      end

      private

      def authorize_download!
        return if pundit_policy_authorized?

        raise ApplicationError.new("unexpected", "authorize before send_download")
      end

      def wait_for_first_chunk(queue)
        loop do
          kind, value = queue.pop
          return value if kind == :chunk
          return nil if kind == :done
          raise value if kind == :error
        end
      end

      def sanitized_filename(filename)
        File.basename(filename.to_s).gsub(/[^0-9A-Za-z._-]/, "_").presence || "download"
      end
    end
  end
end
