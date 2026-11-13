# frozen_string_literal: true

require "rails/engine"
require_relative "../../../app/models/rafelo/core/locales"
require_relative "../../../app/models/rafelo/core/upstream_config"
require_relative "../../../app/models/rafelo/core/flags"

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
        app.config.x.sessions.idle_timeout_seconds = 30 * 60
        app.config.x.sessions.absolute_timeout_seconds = 12 * 60 * 60
        app.config.x.idempotency.retention_seconds = app.config.x.sessions.absolute_timeout_seconds + 60 * 60
        app.config.x.idempotency.stale_margin_seconds = 5
        app.config.x.jobs.upstream_deadline_seconds = 30
        app.config.x.exports.ttl_seconds = 6 * 60 * 60
        app.config.x.sessions.touch_interval_seconds = 5 * 60
        app.config.x.downloads.max_concurrent = 2
        app.config.x.downloads.max_bytes = 52_428_800
      end

      initializer "rafelo_core.upstreams" do |app|
        app.config.x.upstreams = Rafelo::Core::UpstreamConfig.load_all(app.config_for(:upstreams))
        app.config.x.flags = Rafelo::Core::Flags.load(app.config_for(:flags))
      end

      initializer "rafelo_core.locales" do |app|
        app.config.i18n.available_locales = Rafelo::Core::Locales.available.map(&:to_sym)
        app.config.i18n.default_locale = Rafelo::Core::Locales.default.to_sym
        app.config.middleware.insert_after ActionDispatch::DebugExceptions, Rafelo::Core::LocaleMiddleware
        app.config.middleware.insert_after ActionDispatch::RequestId, Rafelo::Core::TraceMiddleware
        app.config.middleware.insert_after Rafelo::Core::TraceMiddleware, Rafelo::Core::BodyLimit
        app.config.middleware.insert_before ActionDispatch::ShowExceptions, Rafelo::Core::PermissionsPolicy
        app.config.after_initialize { Rafelo::Core::Modules.validate! }
        app.config.exceptions_app = ->(env) { Rafelo::Core::ExceptionsApp.call(env) }
      end
    end
  end
end
