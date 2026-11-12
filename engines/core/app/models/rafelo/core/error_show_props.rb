# frozen_string_literal: true

module Rafelo
  module Core
    class ErrorShowProps < PageProps
      def initialize(context:, error:)
        super(context:)
        @error = error
      end

      def envelope
        {
          data: {
            code: @error.code,
            message: @error.message,
            requestId: @context.request_id.to_s,
            traceId: (Current.trace_id.to_s.presence || @context.request_id.to_s),
            retryable: @error.retryable?
          },
          meta: {},
          query: {},
          pagination: nil,
          can: {}
        }
      end
    end
  end
end
