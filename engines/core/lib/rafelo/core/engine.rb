# frozen_string_literal: true

require "rails/engine"

module Rafelo
  module Core
    class Engine < ::Rails::Engine
      isolate_namespace Rafelo::Core

      initializer "rafelo_core.locales" do |app|
        app.config.i18n.available_locales = Rafelo::Core::Locales.available.map(&:to_sym)
        app.config.i18n.default_locale = Rafelo::Core::Locales.default.to_sym
        app.config.middleware.insert_after ActionDispatch::DebugExceptions, Rafelo::Core::LocaleMiddleware
      end
    end
  end
end
