# frozen_string_literal: true

module Rafelo
  module Core
    # The reporting service boundary. A real deployment replaces this with its
    # vendor client; the default writes the allow-listed report as one JSON
    # line and never includes the exception message or any request data.
    class ReportingService
      ALLOWED_KEYS = %w[
        code request_id trace_id release host pid role partition database_role rows
        message stack page path
      ].freeze

      def self.capture(error, handled:, severity:, context:)
        allowed = context.to_h.stringify_keys.slice(*ALLOWED_KEYS)
        Rails.logger.info(
          {
            event: "error_report",
            handled: handled,
            severity: severity,
            context: allowed
          }.to_json
        )
      end
    end
  end
end
