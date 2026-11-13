# frozen_string_literal: true

module Rafelo
  module Core
    ClientError = Class.new(StandardError)

    # The client report is reduced to the OPS-03 fields before it reaches the
    # error subscriber: message, stack, page, path, release, request id and
    # trace id. Unknown or forged formats become "unknown"; kept text is
    # scrubbed and the message/stack are cut.
    class ClientErrorReport
      MESSAGE_LIMIT = 1_000
      STACK_LIMIT = 4_000
      REQUEST_ID = /\A[A-Za-z0-9._:-]{1,128}\z/
      TRACE_ID = /\A[0-9a-f]{32}\z/
      RELEASE = /\A[0-9a-f]{40}\z/

      def self.from(payload)
        new(payload)
      end

      def initialize(payload)
        @payload = payload.is_a?(Hash) ? payload : {}
      end

      def message
        TextScrubber.cut(@payload["message"], MESSAGE_LIMIT)
      end

      def stack
        TextScrubber.cut(@payload["stack"], STACK_LIMIT)
      end

      def to_h
        {
          "message" => message,
          "stack" => stack,
          "page" => page,
          "path" => path,
          "release" => release,
          "request_id" => request_id,
          "trace_id" => trace_id
        }
      end

      def error
        ClientError.new(message)
      end

      private

      def page
        value = TextScrubber.call(@payload["page"]).first(128)
        value.presence || "unknown"
      end

      def path
        value = @payload["path"].to_s.split(/[?#]/, 2).first
        value = TextScrubber.call(value).first(1_024)
        value.start_with?("/") ? value : "unknown"
      end

      def release
        value = @payload["release"].to_s
        value.match?(RELEASE) ? value : "unknown"
      end

      def request_id
        value = @payload["requestId"].to_s
        value.match?(REQUEST_ID) ? value : "unknown"
      end

      def trace_id
        value = @payload["traceId"].to_s
        value.match?(TRACE_ID) && value != "0" * 32 ? value : "unknown"
      end
    end
  end
end
