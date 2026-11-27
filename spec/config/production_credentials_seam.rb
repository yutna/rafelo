# frozen_string_literal: true

# Loaded with RUBYOPT by the production boot specs. It points the production
# credentials at the committed dummy files, so no spec writes the tracked
# production.yml.enc (BE-08, SEC-07).
ENV["BUNDLE_GEMFILE"] ||= ENV.fetch("RAILS_SEAM_GEMFILE")

require "bundler/setup"
require "rails"
require "rails/application/configuration"

module RafeloProductionCredentialsSeam
  private

  def credentials_defaults
    super.merge(
      content_path: root.join("config/credentials/dummy.yml.enc"),
      key_path: root.join("config/credentials/dummy.key")
    )
  end
end

Rails::Application::Configuration.prepend(RafeloProductionCredentialsSeam)
