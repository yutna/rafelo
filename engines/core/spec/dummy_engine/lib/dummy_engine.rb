# frozen_string_literal: true

require_relative "../app/models/dummy_engine/dummy_widgets_props"
require_relative "../app/controllers/dummy_engine/widgets_controller"

module DummyEngine
  class Engine < ::Rails::Engine
    isolate_namespace DummyEngine

    routes.draw do
      get "widgets", to: "widgets#index", as: :widgets
      get "missing_key", to: "widgets#missing_key"
      get "extra_key", to: "widgets#extra_key"
      get "denied", to: "widgets#denied"
      get "flash", to: "widgets#set_flash"
      get "whoami", to: "widgets#whoami"
    end
  end
end
