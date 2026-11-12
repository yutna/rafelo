# frozen_string_literal: true

module Rafelo
  module Core
    UpstreamConfig = Data.define(
      :base_url,
      :open_timeout,
      :read_timeout,
      :write_timeout,
      :max_concurrent_calls,
      :max_response_bytes,
      :retry_budget,
      :idempotency_keys,
      :breaker
    ) do
      REQUIRED = members

      def self.load_all(raw)
        raw.to_h do |name, values|
          attributes = values.to_h.symbolize_keys
          missing = REQUIRED - attributes.keys
          extra = attributes.keys - REQUIRED
          raise ArgumentError, "upstream #{name}: missing #{missing.inspect}" if missing.any?
          raise ArgumentError, "upstream #{name}: unknown #{extra.inspect}" if extra.any?

          [ name.to_sym, new(**attributes.slice(*REQUIRED)) ]
        end.freeze
      end
    end
  end
end
