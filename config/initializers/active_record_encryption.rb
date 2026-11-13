# frozen_string_literal: true

if Rails.env.local?
  Rails.application.config.active_record.encryption.primary_key = "rafelo-test-primary-key-0000001"
  Rails.application.config.active_record.encryption.deterministic_key = "rafelo-test-deterministic-0001"
  Rails.application.config.active_record.encryption.key_derivation_salt = "rafelo-test-salt-000000000001"
else
  Rails.application.config.active_record.encryption.primary_key = ENV.fetch("ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY")
  Rails.application.config.active_record.encryption.deterministic_key = ENV.fetch("ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY")
  Rails.application.config.active_record.encryption.key_derivation_salt = ENV.fetch("ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT")
end
