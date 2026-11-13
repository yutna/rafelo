# frozen_string_literal: true

require "openssl"

module Rafelo
  module Core
    # Builds the one JSON line Lograge writes for a request (OPS-01). Every
    # field comes from the allow-list; nothing else is passed through.
    class LogPayload
      ALLOWED_KEYS = %w[
        time request_id trace_id method path controller action page status
        duration db_time sql_count upstream_calls upstream_time props_bytes
        viewer locale
      ].freeze

      def self.opaque_viewer(viewer_id)
        return if viewer_id.blank?

        key = Rails.application.key_generator.generate_key("rafelo.log.viewer", 32)
        OpenSSL::HMAC.hexdigest("SHA256", key, viewer_id.to_s).first(16)
      end

      def initialize(data:, event_payload:)
        @data = data
        @event_payload = event_payload
      end

      def to_h
        {
          time: Time.current.utc.iso8601(3),
          request_id: request_id,
          trace_id: trace_id,
          method: @data[:method].to_s,
          path: request_path,
          controller: @data[:controller].to_s,
          action: @data[:action].to_s,
          page: env["rafelo.page"].presence,
          status: @data[:status].to_i,
          duration: @data[:duration].to_f.round(2),
          db_time: @data[:db].to_f.round(2),
          sql_count: collector&.sql_count.to_i,
          upstream_calls: collector&.upstream_calls&.to_h || {},
          upstream_time: collector&.upstream_time&.transform_values { |value| value.round(2) } || {},
          props_bytes: env["rafelo.props_bytes"].to_i,
          viewer: env["rafelo.log.viewer"].presence,
          locale: (env["rafelo.locale"].presence || I18n.locale.to_s)
        }
      end

      private

      def request
        @event_payload[:request]
      end

      def env
        request&.env || {}
      end

      def request_id
        env["rafelo.request_id"].presence || request&.request_id.to_s
      end

      def trace_id
        env["rafelo.trace_id"].presence || request_id
      end

      def request_path
        request&.path.presence || @data[:path].to_s.split("?", 2).first.to_s
      end

      def collector
        env["rafelo.request_log"]
      end
    end
  end
end
