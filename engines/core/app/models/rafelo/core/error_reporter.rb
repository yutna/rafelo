# frozen_string_literal: true

module Rafelo
  module Core
    # One place that turns an exception into a Rails.error report carrying the
    # catalog code, request id, trace id and release tag, and one subscriber
    # that forwards the allow-listed context (OPS-03).
    class ErrorReporter
      CONTEXT_KEYS = %w[code request_id trace_id release].freeze
      CLIENT_KEYS = %w[message stack page path release request_id trace_id].freeze

      def self.report(error, handled:, code: nil, request_id: nil, trace_id: nil)
        resolved_code = code || error_code(error)
        Metrics.record_error(resolved_code)
        Rails.error.report(
          error,
          handled: handled,
          severity: :error,
          context: {
            code: resolved_code,
            request_id: (request_id || Current.request_id).to_s.presence || "unknown",
            trace_id: (trace_id || Current.trace_id).to_s.presence || "unknown",
            release: Release.call
          }
        )
      end

      def self.error_code(error)
        error.respond_to?(:code) ? error.code.to_s : "unexpected"
      end

      # The error subscriber is one of the few objects allowed to read Current
      # (BE-09); it forwards only the allow-listed server context or the
      # already-scrubbed client report.
      class Subscriber
        def report(error, handled:, severity:, context:, source: nil)
          allowed = context.to_h.stringify_keys
          allowed = if allowed.key?("message")
            allowed.slice(*CLIENT_KEYS)
          else
            allowed.slice(*CONTEXT_KEYS)
          end
          ReportingService.capture(error, handled: handled, severity: severity, context: allowed)
        rescue StandardError => error
          Rails.logger.warn("error report forward failed: #{error.class.name}")
        end
      end
    end
  end
end
