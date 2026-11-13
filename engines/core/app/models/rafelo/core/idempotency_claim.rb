# frozen_string_literal: true

require "digest"
require "openssl"

module Rafelo
  module Core
    # One row per form token. The claim, takeover and outcome are separate
    # statements; no transaction spans the upstream call (BE-15, BE-20).
    class IdempotencyClaim
      AMBIGUOUS = %w[upstream.timeout upstream.unavailable upstream.circuit_open unexpected].freeze
      STALE_MARGIN = 5

      def self.call(controller, token:, payload:, back:, upstream_idempotent: false, &block)
        new(
          controller: controller,
          token: token,
          payload: payload,
          back: back,
          upstream_idempotent: upstream_idempotent
        ).call(&block)
      end

      def initialize(controller:, token:, payload:, back:, upstream_idempotent: false)
        @controller = controller
        @token = token.to_s
        @payload = payload
        @back = back
        @upstream_idempotent = upstream_idempotent
      end

      def call(&block)
        return refuse(:invalid_token) unless valid_token?
        return refuse(:invalid_token) if viewer_id.blank?

        @row = find_or_create
        return refuse(:invalid_token) unless row_belongs_to_claim?(@row)
        return perform(&block) if @created

        case @row.status
        when "succeeded" then replay(@row)
        when "unknown" then refuse(:unknown)
        when "pending" then claim_pending(@row, &block)
        when "failed" then take_over(@row, &block)
        else refuse(:invalid_token)
        end
      end

      private

      attr_reader :controller, :payload, :back

      def valid_token?
        @token_data = FormToken.verify(@token, session_id: Current.session&.id)
        @token_data.present?
      end

      def viewer_id
        @viewer_id ||= Current.session&.viewer_id.to_s
      end

      def token_digest
        @token_digest ||= Digest::SHA256.hexdigest(@token)
      end

      def payload_digest
        @payload_digest ||= Digest::SHA256.hexdigest(normalized_payload)
      end

      def normalized_payload
        JSON.generate(deep_sort(payload))
      rescue JSON::GeneratorError
        payload.to_s
      end

      def deep_sort(value)
        case value
        when Hash
          value.to_h.sort_by { |key, _| key.to_s }.to_h { |key, item| [ key.to_s, deep_sort(item) ] }
        when Array
          value.map { |item| deep_sort(item) }
        else
          value
        end
      end

      def find_or_create
        existing = IdempotencyKey.find_by(token_digest: token_digest)
        return existing if existing

        @created = true
        IdempotencyKey.create!(
          token_digest: token_digest,
          viewer_id: viewer_id,
          payload_digest: payload_digest,
          status: "pending",
          attempt: 1,
          claimed_at: Time.current,
          expires_at: FormToken.retention.from_now
        )
      rescue ActiveRecord::RecordNotUnique
        IdempotencyKey.find_by!(token_digest: token_digest)
      end

      def row_belongs_to_claim?(row)
        row.viewer_id == viewer_id && row.payload_digest == payload_digest
      end

      def replay(row)
        return refuse(:unknown) if row.outcome.blank?

        controller.redirect_to row.outcome, status: :see_other
        :replayed
      end

      def claim_pending(row, &block)
        if stale_pending?(row)
          take_over(row, &block)
        else
          refuse(:still_processing)
        end
      end

      def stale_pending?(row)
        row.claimed_at.nil? || row.claimed_at < (request_deadline + STALE_MARGIN).seconds.ago
      end

      def take_over(row, &block)
        scope = IdempotencyKey.where(id: row.id, status: row.status, attempt: row.attempt)
        if row.status == "pending"
          scope = scope.where("claimed_at IS NULL OR claimed_at < now() - make_interval(secs => ?)", request_deadline + STALE_MARGIN)
        end
        claimed = scope
          .update_all(status: "pending", attempt: row.attempt + 1, claimed_at: Time.current, expires_at: FormToken.retention.from_now)
          .positive?
        return refuse(:still_processing) unless claimed

        @row = IdempotencyKey.find(row.id)
        perform(&block)
      end

      def perform
        yield idempotency_key
        succeed!(controller.response.location)
        :performed
      rescue StandardError => error
        fail!(error)
        raise
      end

      def succeed!(location)
        update_outcome("succeeded", location)
      end

      def fail!(error)
        ambiguous = ambiguous?(error)
        status = ambiguous && !@upstream_idempotent ? "unknown" : "failed"
        update_outcome(status, error.respond_to?(:code) ? error.code : error.class.name)
      end

      def update_outcome(status, outcome)
        IdempotencyKey
          .where(id: @row.id, status: "pending", attempt: @row.attempt)
          .update_all(status: status, outcome: outcome, updated_at: Time.current)
      end

      def ambiguous?(error)
        !error.is_a?(ApplicationError) || AMBIGUOUS.include?(error.code)
      end

      def idempotency_key
        @idempotency_key ||= OpenSSL::HMAC.hexdigest(
          "SHA256",
          Rails.application.key_generator.generate_key("rafelo.idempotency", 32),
          "#{viewer_id}:#{@token}"
        )
      end

      def request_deadline
        Rails.application.config.x.requests.upstream_deadline_seconds
      end

      def refuse(reason)
        controller.redirect_after_write(
          back,
          errors: { "base" => I18n.t("core.idempotency.#{reason}") }
        )
        :handled
      end
    end
  end
end
