# frozen_string_literal: true

module Rafelo
  module Core
    # The reporting service boundary. A real deployment replaces this with its
    # vendor client; the default writes the allow-listed report as one JSON
    # line and never includes the exception message or any request data.
    class ReportingService
      def self.capture(error, handled:, severity:, context:)
        Rails.logger.info(
          {
            event: "error_report",
            handled: handled,
            severity: severity,
            context: context
          }.to_json
        )
      end
    end
  end
end
