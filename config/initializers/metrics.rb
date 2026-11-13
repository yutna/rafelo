# frozen_string_literal: true

Rails.application.config.after_initialize do
  Rafelo::Core::Metrics.install!
end
