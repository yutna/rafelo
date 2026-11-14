# frozen_string_literal: true

# Production secrets live in the encrypted credentials (BE-08). The ENV
# fallbacks exist for the production boot specs, which run without a
# production credentials key; deployment never sets those variables.
if Rails.env.local?
  Rails.application.config.active_record.encryption.primary_key = "acme-test-primary-key-0000001"
  Rails.application.config.active_record.encryption.deterministic_key = "acme-test-deterministic-0001"
  Rails.application.config.active_record.encryption.key_derivation_salt = "acme-test-salt-000000000001"
else
  settings = {
    primary_key: [ "ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY", :primary_key ],
    deterministic_key: [ "ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY", :deterministic_key ],
    key_derivation_salt: [ "ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT", :key_derivation_salt ]
  }

  settings.each do |attribute, (env_key, credential_key)|
    value = ENV[env_key].presence || Rails.application.credentials.dig(:active_record_encryption, credential_key)
    raise "Active Record encryption #{attribute} is missing" if value.blank?

    Rails.application.config.active_record.encryption.public_send("#{attribute}=", value)
  end
end
