# frozen_string_literal: true

require "uri"

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
      :service_token_gateways,
      :breaker
    ) do
      REQUIRED = members
      BREAKER_KEYS = %i[failure_threshold cool_off].freeze

      def self.load_all(raw)
        raw.to_h do |name, values|
          attributes = values.to_h.deep_symbolize_keys
          missing = REQUIRED - attributes.keys
          extra = attributes.keys - REQUIRED
          raise ArgumentError, "upstream #{name}: missing #{missing.inspect}" if missing.any?
          raise ArgumentError, "upstream #{name}: unknown #{extra.inspect}" if extra.any?

          [ name.to_sym, build(name, attributes) ]
        end.freeze
      end

      def self.build(name, attributes)
        base_url = attributes.fetch(:base_url).to_s
        uri = URI.parse(base_url) rescue nil
        unless uri.is_a?(URI::HTTP) && uri.host && !base_url.strip.empty?
          raise ArgumentError, "upstream #{name}: base_url must be an http(s) URL"
        end
        %i[open_timeout read_timeout write_timeout].each do |key|
          value = attributes.fetch(key)
          raise ArgumentError, "upstream #{name}: #{key} must be positive" unless value.is_a?(Numeric) && value.positive?
        end
        unless attributes.fetch(:max_concurrent_calls).is_a?(Integer) && attributes.fetch(:max_concurrent_calls).positive?
          raise ArgumentError, "upstream #{name}: max_concurrent_calls must be a positive integer"
        end
        unless attributes.fetch(:max_response_bytes).is_a?(Integer) && attributes.fetch(:max_response_bytes).positive?
          raise ArgumentError, "upstream #{name}: max_response_bytes must be a positive integer"
        end
        budget = attributes.fetch(:retry_budget)
        raise ArgumentError, "upstream #{name}: retry_budget must be 0..1" unless budget.is_a?(Numeric) && budget.between?(0, 1)
        unless [ true, false ].include?(attributes.fetch(:idempotency_keys))
          raise ArgumentError, "upstream #{name}: idempotency_keys must be boolean"
        end
        gateways = attributes.fetch(:service_token_gateways)
        unless gateways.is_a?(Array) && gateways.all? { |gateway| gateway.is_a?(String) }
          raise ArgumentError, "upstream #{name}: service_token_gateways must be strings"
        end
        breaker = attributes.fetch(:breaker).to_h.deep_symbolize_keys
        unless breaker.keys.sort == BREAKER_KEYS.sort &&
               breaker[:failure_threshold].is_a?(Integer) && breaker[:failure_threshold].positive? &&
               breaker[:cool_off].is_a?(Numeric) && breaker[:cool_off].positive?
          raise ArgumentError, "upstream #{name}: breaker must hold failure_threshold and cool_off"
        end

        new(
          base_url: base_url,
          open_timeout: attributes[:open_timeout],
          read_timeout: attributes[:read_timeout],
          write_timeout: attributes[:write_timeout],
          max_concurrent_calls: attributes[:max_concurrent_calls],
          max_response_bytes: attributes[:max_response_bytes],
          retry_budget: budget,
          idempotency_keys: attributes[:idempotency_keys],
          service_token_gateways: gateways.freeze,
          breaker: breaker.freeze
        ).freeze
      end
    end
  end
end
