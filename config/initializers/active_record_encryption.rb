# frozen_string_literal: true

# Production secrets live in the encrypted credentials (BE-08). The test
# values below apply only outside production; production reads the credentials
# and never falls back to ENV.
if Rails.env.local?
  Rails.application.config.active_record.encryption.primary_key = "acme-test-primary-key-0000001"
  Rails.application.config.active_record.encryption.deterministic_key = "acme-test-deterministic-0001"
  Rails.application.config.active_record.encryption.key_derivation_salt = "acme-test-salt-000000000001"
else
  settings = {
    primary_key: :primary_key,
    deterministic_key: :deterministic_key,
    key_derivation_salt: :key_derivation_salt
  }

  settings.each do |attribute, credential_key|
    value = Rails.application.credentials.dig(:active_record_encryption, credential_key)
    raise "Active Record encryption #{attribute} is missing from the production credentials" if value.blank?

    Rails.application.config.active_record.encryption.public_send("#{attribute}=", value)
  end
end
