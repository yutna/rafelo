# frozen_string_literal: true

require "rails/engine"
require_relative "../../../app/models/rafelo/core/locales"
require_relative "../../../app/models/rafelo/core/upstream_config"
require_relative "../../../app/models/rafelo/core/budgets"
require_relative "../../../app/models/rafelo/core/flags"

module Rafelo
  module Core
    class Engine < ::Rails::Engine
      isolate_namespace Rafelo::Core

      initializer "rafelo_core.migrations" do |app|
        app.config.paths["db/migrate"] << root.join("db/migrate")
      end

      initializer "rafelo_core.runtime" do |app|
        core_config = app.config_for(:core)
        app.config.x.executor = Data.define(:size).new(size: core_config.fetch(:executor).fetch(:size).to_i)
        app.config.x.puma_threads = core_config.fetch(:puma_threads, 3).to_i
        app.config.x.process = ActiveSupport::OrderedOptions.new
        app.config.x.process.role = core_config.fetch(:process).fetch(:role).to_s
        app.config.x.requests.upstream_deadline_seconds = 10
        app.config.x.sessions.refresh_timeout_seconds = 15
        app.config.x.sessions.idle_timeout_seconds = 30 * 60
        app.config.x.sessions.absolute_timeout_seconds = 12 * 60 * 60
        app.config.x.idempotency.retention_seconds = app.config.x.sessions.absolute_timeout_seconds + 60 * 60
        app.config.x.idempotency.stale_margin_seconds = 5
        app.config.x.jobs.upstream_deadline_seconds = 30
        app.config.x.exports.ttl_seconds = 6 * 60 * 60
        app.config.x.audit.retention_days = 365
        app.config.x.audit.partition_months_ahead = 2
        app.config.x.database.runtime_role = core_config.dig(:database, :runtime_role)
        app.config.x.sessions.touch_interval_seconds = 5 * 60
        app.config.x.downloads.max_concurrent = 2
        app.config.x.downloads.max_bytes = 52_428_800
      end

      initializer "rafelo_core.upstreams" do |app|
        app.config.x.upstreams = Rafelo::Core::UpstreamConfig.load_all(app.config_for(:upstreams))
        app.config.x.flags = Rafelo::Core::Flags.load(app.config_for(:flags))
        app.config.x.budgets = Rafelo::Core::Budgets.load(root: app.root)
        app.config.x.budgets.validate!(app.config.x.upstreams.keys)
      end

      initializer "rafelo_core.locales" do |app|
        app.config.i18n.available_locales = Rafelo::Core::Locales.available.map(&:to_sym)
        app.config.i18n.default_locale = Rafelo::Core::Locales.default.to_sym
        app.config.middleware.insert_after ActionDispatch::DebugExceptions, Rafelo::Core::LocaleMiddleware
        app.config.middleware.insert_after ActionDispatch::RequestId, Rafelo::Core::TraceMiddleware
        app.config.middleware.insert_after Rafelo::Core::TraceMiddleware, Rafelo::Core::LogContextMiddleware
        app.config.middleware.insert_after Rafelo::Core::LogContextMiddleware, Rafelo::Core::BodyLimit
        app.config.middleware.insert_before ActionDispatch::ShowExceptions, Rafelo::Core::PermissionsPolicy
        app.config.after_initialize { Rafelo::Core::Modules.validate! }
        app.config.exceptions_app = ->(env) { Rafelo::Core::ExceptionsApp.call(env) }
      end
    end
  end
end
