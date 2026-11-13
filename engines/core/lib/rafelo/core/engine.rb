# frozen_string_literal: true

require "rails/engine"
require_relative "../../../app/models/rafelo/core/locales"
require_relative "../../../app/models/rafelo/core/upstream_config"

module Rafelo
  module Core
    class Engine < ::Rails::Engine
      isolate_namespace Rafelo::Core

      initializer "rafelo_core.migrations" do |app|
        app.config.paths["db/migrate"] << root.join("db/migrate")
      end

      initializer "rafelo_core.runtime" do |app|
        app.config.x.executor_threads = 4
        app.config.x.puma_threads = ENV.fetch("RAILS_MAX_THREADS", 3).to_i
        app.config.x.requests.upstream_deadline_seconds = 10
        app.config.x.sessions.refresh_timeout_seconds = 15
        app.config.x.downloads.max_concurrent = 2
        app.config.x.downloads.max_bytes = 52_428_800
      end

      initializer "rafelo_core.upstreams" do |app|
        app.config.x.upstreams = Rafelo::Core::UpstreamConfig.load_all(app.config_for(:upstreams))
      end

      initializer "rafelo_core.locales" do |app|
        app.config.i18n.available_locales = Rafelo::Core::Locales.available.map(&:to_sym)
        app.config.i18n.default_locale = Rafelo::Core::Locales.default.to_sym
        app.config.middleware.insert_after ActionDispatch::DebugExceptions, Rafelo::Core::LocaleMiddleware
        app.config.after_initialize { Rafelo::Core::Modules.validate! }
        app.config.exceptions_app = ->(env) { Rafelo::Core::ExceptionsApp.call(env) }
      end
    end
  end
end
