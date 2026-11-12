# frozen_string_literal: true

require "rails/engine"
require_relative "../../../app/models/rafelo/core/locales"

module Rafelo
  module Core
    class Engine < ::Rails::Engine
      isolate_namespace Rafelo::Core

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
