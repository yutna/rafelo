# frozen_string_literal: true

require "json"
require "uri"

module Rafelo
  module Core
    # One parsed CSP report. The endpoint logs exactly the fields OPS-01
    # allows: the effective directive, the blocked origin, the document path
    # without its query string, the source origin and line, and the release.
    # Every value is coerced and bounded; nothing else from the report is kept.
    class CspReport
      BLOCKED_KINDS = %w[inline eval self].freeze
      TEXT_LIMIT = 256

      def self.from(raw_body)
        payload = JSON.parse(raw_body.presence || "{}")
        entries = payload.is_a?(Array) ? payload : [ payload ]
        entries.filter_map do |entry|
          next unless entry.is_a?(Hash)

          report = new(entry)
          report unless report.empty?
        end
      end

      def initialize(entry)
        @body = entry["body"].is_a?(Hash) ? entry["body"] : entry["csp-report"]
        @body = entry if @body.nil? && entry.keys.any? { |key| key.include?("-") || key.match?(/[A-Z]/) }
        @body = {} unless @body.is_a?(Hash)
      end

      def empty?
        @body.empty?
      end

      def to_log
        {
          event: "csp_report",
          directive: text(fetch("effective-directive", "effectiveDirective", "violated-directive", "violatedDirective")),
          blocked_origin: blocked_origin,
          document_path: document_path,
          source_origin: origin(fetch("source-file", "sourceFile")),
          source_line: line_number,
          release: Release.call
        }
      end

      private

      def fetch(*keys)
        keys.each do |key|
          value = @body[key]
          return value unless value.nil?
        end
        nil
      end

      def blocked_origin
        value = text(fetch("blocked-uri", "blockedURL"))
        return "unknown" if value.empty?
        return value if BLOCKED_KINDS.include?(value)

        origin(value) || "unknown"
      end

      def document_path
        value = text(fetch("document-uri", "documentURL"))
        return nil if value.empty?

        URI.parse(value).path
      rescue URI::InvalidURIError
        nil
      end

      # Only http(s) URIs have an origin. Other schemes (javascript:, data:,
      # blob:, about:) reduce to a scheme label; relative values are unknown.
      # Request input must never raise from a log formatter (SEC-05).
      def origin(value)
        value = text(value)
        return nil if value.empty?

        uri = URI.parse(value)
        return uri.origin if uri.is_a?(URI::HTTP)
        return "#{uri.scheme}:" if uri.scheme

        "unknown"
      rescue URI::Error
        "unknown"
      end

      def line_number
        value = fetch("line-number", "lineNumber")
        Integer(value)
      rescue ArgumentError, TypeError
        nil
      end

      def text(value)
        value.to_s.strip[0, TEXT_LIMIT]
      end
    end
  end
end
