# frozen_string_literal: true

Rails.application.config.after_initialize do
  Rails.error.subscribe(Rafelo::Core::ErrorReporter::Subscriber.new)
end
