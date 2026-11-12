# frozen_string_literal: true

require "faraday/net_http_persistent"
require "stoplight"

module Rafelo
  module Core
    class UpstreamClient
      FORBIDDEN_HEADERS = %w[authorization traceparent x-request-id idempotency-key if-match].freeze
      RETRYABLE_STATUS = [ 429, 500, 502, 503, 504 ].freeze

      def self.for(name, config:, token_provider:, budget: nil, request_id: nil, trace_id: nil)
        new(name: name, config: config, token_provider: token_provider, budget: budget,
            request_id: request_id, trace_id: trace_id)
      end

      def initialize(name:, config:, token_provider:, budget: nil, request_id: nil, trace_id: nil)
        @name = name.to_sym
        @config = config
        @token_provider = token_provider
        @budget = budget
        @request_id = request_id
        @trace_id = trace_id
        @breaker = Stoplight(name, threshold: config.breaker.fetch(:failure_threshold),
                                    cool_off_time: config.breaker.fetch(:cool_off))
      end

      def get(path, params: nil, headers: {}, if_match: nil)
        request(:get, path, params: params, headers: headers, if_match: if_match)
      end

      def head(path, headers: {}, if_match: nil)
        request(:head, path, headers: headers, if_match: if_match)
      end

      def post(path, body:, headers: {}, idempotency_key: nil)
        request(:post, path, body: body, headers: headers, idempotency_key: idempotency_key)
      end

      def patch(path, body:, headers: {}, idempotency_key: nil, if_match: nil)
        request(:patch, path, body: body, headers: headers, idempotency_key: idempotency_key, if_match: if_match)
      end

      def delete(path, headers: {}, idempotency_key: nil, if_match: nil)
        request(:delete, path, headers: headers, idempotency_key: idempotency_key, if_match: if_match)
      end

      def request(method, path, params: nil, body: nil, headers: {}, idempotency_key: nil, if_match: nil)
        validate_headers!(headers)
        @budget&.consume!(@name)
        @breaker.run do
          response = perform(method, path, params: params, body: body, headers: headers,
                             idempotency_key: idempotency_key, if_match: if_match)
          check_size!(response)
          map_status!(response)
          response
        end
      rescue Stoplight::Error::RedLight
        raise ApplicationError.new("upstream.circuit_open")
      rescue Faraday::TimeoutError
        raise ApplicationError.new("upstream.timeout")
      rescue Faraday::ConnectionFailed
        raise ApplicationError.new("upstream.unavailable")
      end

      private

      def perform(method, path, params:, body:, headers:, idempotency_key:, if_match:)
        attempts = 0
        begin
          attempts += 1
          response = connection.run_request(method, path, body, request_headers(headers, idempotency_key, if_match)) do |request|
            request.params.update(params) if params
          end
          if attempts < 3 && %i[get head].include?(method) && RETRYABLE_STATUS.include?(response.status)
            sleep(backoff_for(response, attempts))
            raise Retry
          end
          response
        rescue Retry
          retry
        end
      end
      Retry = Class.new(StandardError)

      def connection
        @connection ||= Faraday.new(url: @config.base_url) do |faraday|
          faraday.adapter :net_http_persistent
          faraday.options.open_timeout = @config.open_timeout
          faraday.options.timeout = @config.read_timeout
          faraday.options.write_timeout = @config.write_timeout
        end
      end

      def request_headers(headers, idempotency_key, if_match)
        result = headers.to_h.transform_keys(&:to_s)
        result["X-Request-Id"] = @request_id.to_s if @request_id
        result["traceparent"] = "00-#{@trace_id}-#{@request_id}-01" if @trace_id && @request_id
        result["Authorization"] = "Bearer #{@token_provider.token}" if @token_provider.respond_to?(:token) && @token_provider.token
        result["Idempotency-Key"] = idempotency_key.to_s if idempotency_key
        result["If-Match"] = if_match.to_s if if_match
        result
      end

      def validate_headers!(headers)
        forbidden = headers.keys.map { |key| key.to_s.downcase } & FORBIDDEN_HEADERS
        return if forbidden.empty?

        raise ArgumentError, "a gateway may not set #{forbidden.join(', ')}"
      end

      def check_size!(response)
        bytes = response.body.to_s.bytesize
        return if bytes <= @config.max_response_bytes

        raise ApplicationError.new("unexpected", "Upstream response exceeded #{@config.max_response_bytes} bytes")
      end

      def map_status!(response)
        code = case response.status
        when 200..299, 304 then return response
        when 401 then "auth.expired"
        when 403 then "auth.forbidden"
        when 404, 410 then "resource.not_found"
        when 409, 412 then "resource.conflict"
        when 413 then "validation.failed"
        when 422 then "validation.failed"
        when 429 then "upstream.unavailable"
        when 500..599 then "upstream.unavailable"
        else "unexpected"
        end
        raise ApplicationError.new(code)
      end

      def backoff_for(response, attempt)
        retry_after = response.headers["retry-after"].to_f
        retry_after.positive? ? [ retry_after, 1.0 ].min : 0.05 * attempt
      end
    end
  end
end
