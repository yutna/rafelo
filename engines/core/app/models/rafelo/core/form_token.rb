# frozen_string_literal: true

module Rafelo
  module Core
    class FormToken
      VERIFIER = "rafelo.form-token"

      def self.issue(session_id:)
        return if session_id.blank?

        verifier.generate(
          {
            "session_id" => session_id.to_s,
            "issued_at" => Time.current.to_i,
            "nonce" => SecureRandom.urlsafe_base64(32)
          }
        )
      end

      def self.verify(token, session_id:)
        return if token.blank? || session_id.blank?

        data = verifier.verified(token.to_s)
        return unless data.is_a?(Hash)
        return unless data["session_id"] == session_id.to_s
        return if Time.zone.at(data.fetch("issued_at").to_i) < retention.seconds.ago

        data
      rescue ActiveSupport::MessageVerifier::InvalidSignature, KeyError, TypeError
        nil
      end

      def self.retention
        Rails.application.config.x.idempotency.retention_seconds.seconds
      end

      def self.verifier
        Rails.application.message_verifier(VERIFIER)
      end
    end
  end
end
