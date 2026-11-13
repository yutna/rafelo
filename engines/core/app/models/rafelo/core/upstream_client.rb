# frozen_string_literal: true

require "faraday/net_http_persistent"
require "stoplight"

module Rafelo
  module Core
    UpstreamResponse = Data.define(:status, :headers, :body)

    class UpstreamClient
      FORBIDDEN_HEADERS = %w[authorization traceparent x-request-id idempotency-key if-match].freeze
      RETRYABLE_STATUS = [ 429, 500, 502, 503, 504 ].freeze
      class << self
        attr_accessor :transaction_baseline
      end
      self.transaction_baseline = 0

      def self.for(name, config:, token_provider:, budget: nil, request_id: nil, trace_id: nil, deadline: nil)
        new(name: name, config: config, token_provider: token_provider, budget: budget,
            request_id: request_id, trace_id: trace_id, deadline: deadline)
      end

      def initialize(name:, config:, token_provider:, budget: nil, request_id: nil, trace_id: nil, deadline: nil)
        @name = name.to_sym
        @config = config
        @token_provider = token_provider
        @budget = budget
        @request_id = request_id
        @trace_id = trace_id
        @deadline = deadline || RequestDeadline.new(Rails.application.config.x.requests.upstream_deadline_seconds)
        @breaker = Stoplight(name, threshold: config.breaker.fetch(:failure_threshold),
                                    cool_off_time: config.breaker.fetch(:cool_off))
        @bulkhead = self.class.bulkhead_for(@name, config.max_concurrent_calls)
        @calls = 0
        @retries = 0
      end

      class << self
        def bulkhead_for(name, limit)
          @bulkheads ||= {}
          @bulkhead_mutex ||= Mutex.new
          @bulkhead_mutex.synchronize { @bulkheads[name] ||= Bulkhead.new(limit) }
        end
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
        validate_path!(path)
        ensure_no_transaction!
        raise ApplicationError.new("upstream.timeout") if @deadline.expired?

        @budget&.consume!(@name)
        @calls += 1
        response = @bulkhead.call do
          @breaker.run do
            perform(method, path, params: params, body: body, headers: headers,
                    idempotency_key: idempotency_key, if_match: if_match)
          end
        end
        map_status!(response)
        response
      rescue Stoplight::Error::RedLight
        raise ApplicationError.new("upstream.circuit_open")
      rescue Faraday::TimeoutError
        raise ApplicationError.new("upstream.timeout")
      rescue Faraday::ConnectionFailed
        raise ApplicationError.new("upstream.unavailable")
      end

      # Streams a body only after the first response callback has checked the
      # status and Content-Length; the caller has written no bytes yet (BE-18).
      def stream(method, path, headers: {}, max_bytes: nil, &block)
        validate_headers!(headers)
        validate_path!(path)
        ensure_no_transaction!
        raise ApplicationError.new("upstream.timeout") if @deadline.expired?

        limit = max_bytes || @config.max_response_bytes
        @budget&.consume!(@name)
        @calls += 1
        first = true
        total = 0
        @bulkhead.call do
          @breaker.run do
            connection.run_request(method, path, nil, request_headers(headers, nil, nil)) do |request|
              request.options.timeout = [ @config.read_timeout, @deadline.remaining ].min
              request.options.open_timeout = [ @config.open_timeout, @deadline.remaining ].min
              request.options.write_timeout = [ @config.write_timeout, @deadline.remaining ].min
              request.options.on_data = proc do |chunk, _size, env|
                if first
                  first = false
                  map_status!(env)
                  expected = env.response_headers["content-length"].to_i
                  raise ApplicationError.new("unexpected", "Download exceeded #{limit} bytes") if expected.positive? && expected > limit
                end
                raise ApplicationError.new("upstream.timeout") if @deadline.expired?

                total += chunk.bytesize
                raise ApplicationError.new("unexpected", "Download exceeded #{limit} bytes") if total > limit

                block.call(chunk)
              end
            end
          end
        end
        total
      rescue Stoplight::Error::RedLight
        raise ApplicationError.new("upstream.circuit_open")
      rescue Faraday::TimeoutError
        raise ApplicationError.new("upstream.timeout")
      rescue Faraday::ConnectionFailed
        raise ApplicationError.new("upstream.unavailable")
      end

      private

      def perform(method, path, params:, body:, headers:, idempotency_key:, if_match:)
        attempt = 0
        loop do
          attempt += 1
          response = perform_once(method, path, params: params, body: body, headers: headers,
                                  idempotency_key: idempotency_key, if_match: if_match)
          if (response.status == 429 || response.status >= 500) && %i[get head].include?(method) &&
             attempt < 2 && retry_allowed? && !@deadline.expired?
            delay = backoff_for(response, attempt)
            if delay < @deadline.remaining
              sleep(delay)
              @retries += 1
              next
            end
          end
          raise ApplicationError.new("upstream.unavailable") if response.status >= 500
          return response
        end
      end

      def perform_once(method, path, params:, body:, headers:, idempotency_key:, if_match:)
        collected = +""
        response = connection.run_request(method, path, body, request_headers(headers, idempotency_key, if_match)) do |request|
          request.params.update(params) if params
          request.options.timeout = [ @config.read_timeout, @deadline.remaining ].min
          request.options.open_timeout = [ @config.open_timeout, @deadline.remaining ].min
          request.options.write_timeout = [ @config.write_timeout, @deadline.remaining ].min
          request.options.on_data = proc do |chunk, _size|
            raise ApplicationError.new("upstream.timeout") if @deadline.expired?

            collected << chunk
            if collected.bytesize > @config.max_response_bytes
              raise ApplicationError.new("unexpected", "Upstream response exceeded #{@config.max_response_bytes} bytes")
            end
          end
        end
        body = collected.bytesize.positive? ? collected : response.body.to_s
        if body.bytesize > @config.max_response_bytes
          raise ApplicationError.new("unexpected", "Upstream response exceeded #{@config.max_response_bytes} bytes")
        end
        expected = response.headers["content-length"].to_i
        bodyless = method == :head || (100..199).cover?(response.status) || [ 204, 304 ].include?(response.status)
        encoded = !response.headers["content-encoding"].to_s.empty?
        if !bodyless && !encoded && expected.positive? && body.bytesize < expected
          raise ApplicationError.new("upstream.unavailable", "Upstream closed before the full response arrived")
        end

        UpstreamResponse.new(status: response.status, headers: response.headers, body: body)
      end

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
        raise ArgumentError, "token provider must respond to #token" unless @token_provider.respond_to?(:token)

        result["X-Request-Id"] = @request_id.to_s if @request_id
        result["traceparent"] = "00-#{@trace_id}-#{@request_id}-01" if @trace_id && @request_id
        result["Authorization"] = "Bearer #{@token_provider.token}" if @token_provider.token
        result["Idempotency-Key"] = idempotency_key.to_s if idempotency_key && @config.idempotency_keys
        result["If-Match"] = if_match.to_s if if_match
        result
      end

      def validate_headers!(headers)
        forbidden = headers.keys.map { |key| key.to_s.downcase } & FORBIDDEN_HEADERS
        return if forbidden.empty?

        raise ArgumentError, "a gateway may not set #{forbidden.join(', ')}"
      end

      def validate_path!(path)
        raise ArgumentError, "path must be a relative string" unless path.is_a?(String)
        raise ArgumentError, "path must not start with /" if path.start_with?("/")
        raise ArgumentError, "path must not be an absolute URL" if path.match?(/\A[a-z][a-z0-9+.-]*:/i)
        raise ArgumentError, "path must not contain a delimiter" if path.match?(/[?#\\\x00-\x1f]/)

        segments = path.split("/", -1)
        return unless segments.empty? || segments.any? { |segment| segment.empty? || segment == "." || segment == ".." }

        raise ApplicationError.new("resource.not_found")
      end

      def ensure_no_transaction!
        return unless defined?(ActiveRecord::Base)

        open = ActiveRecord::Base.connection.open_transactions
        return if open <= self.class.transaction_baseline

        raise ApplicationError.new("unexpected", "Upstream call inside a database transaction")
      end

      def retry_allowed?
        @retries + 1 <= (@calls * @config.retry_budget).floor
      end

      def map_status!(response)
        code = case response.status
        when 200..299, 304 then return response
        when 401 then "auth.expired"
        when 403
          Current.session&.mark_grants_stale!
          "auth.forbidden"
        when 404, 410 then "resource.not_found"
        when 409, 412 then "resource.conflict"
        when 413, 422 then "validation.failed"
        when 429 then "upstream.unavailable"
        else "unexpected"
        end
        raise ApplicationError.new(code)
      end

      def backoff_for(response, attempt)
        retry_after = response.headers["retry-after"].to_f
        retry_after.positive? ? retry_after : 0.05 * attempt
      end
    end
  end
end
