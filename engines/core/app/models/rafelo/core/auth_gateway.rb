# frozen_string_literal: true

module Rafelo
  module Core
    class AuthGateway
      Result = Data.define(:viewer, :access_token, :refresh_token, :access_expires_at, :grants)

      def initialize(budget:, request_id:, trace_id:)
        @budget = budget
        @request_id = request_id
        @trace_id = trace_id
      end

      def refresh(refresh_token:)
        client = client_for_refresh
        payload = JSON.parse(
          client.post(
            "auth/refresh",
            body: { refresh_token: refresh_token }.to_json,
            headers: { "Content-Type" => "application/json" }
          ).body
        )
        result(payload)
      rescue JSON::ParserError
        raise ApplicationError.new("unexpected", "Upstream returned malformed JSON")
      end

      def sign_in(email:, password:)
        client = UpstreamClient.for(
          :api,
          config: Rails.application.config.x.upstreams.fetch(:api),
          token_provider: NullTokenProvider.new,
          budget: @budget,
          request_id: @request_id,
          trace_id: @trace_id,
          kind: :auth
        )
        payload = JSON.parse(
          client.post(
            "auth/sign_in",
            body: { email: email, password: password }.to_json,
            headers: { "Content-Type" => "application/json" }
          ).body
        )
        result(payload)
      end

      private

      def client_for_refresh
        UpstreamClient.for(
          :api,
          config: Rails.application.config.x.upstreams.fetch(:api),
          token_provider: NullTokenProvider.new,
          budget: @budget,
          request_id: @request_id,
          trace_id: @trace_id,
          kind: :session_refresh
        )
      end

      def result(payload)
        Result.new(
          viewer: Viewer.new(id: payload.dig("viewer", "id").to_s, name: payload.dig("viewer", "name").to_s),
          access_token: payload.fetch("access_token"),
          refresh_token: payload.fetch("refresh_token"),
          access_expires_at: Time.current + payload.fetch("expires_in").to_i.seconds,
          grants: Array(payload["grants"])
        )
      end
    end
  end
end
