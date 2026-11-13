# frozen_string_literal: true

# One JSON line per request, built only from Rafelo::Core::LogPayload's
# allow-list. keep_original_rails_log=false removes Rails' own request line,
# which prints parameters (OPS-01).
Rails.application.configure do
  config.lograge.enabled = true
  config.lograge.keep_original_rails_log = false
  config.lograge.formatter = Lograge::Formatters::Json.new
  config.lograge.before_format = lambda do |data, payload|
    Rafelo::Core::LogPayload.new(data: data, event_payload: payload).to_h
  end
end
