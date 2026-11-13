# frozen_string_literal: true

require_relative "../app/models/dummy_engine/dummy_widgets_props"
require_relative "../app/models/dummy_engine/dummy_widget_form"
require_relative "../app/controllers/dummy_engine/widgets_controller"
require_relative "../app/controllers/dummy_engine/downloads_controller"
require_relative "../app/controllers/dummy_engine/exports_controller"

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
      get "expired", to: "widgets#expired"
      get "download", to: "downloads#show"
      get "download_failure", to: "downloads#failure"
      get "export/:id", to: "exports#show"
      post "widgets", to: "widgets#create"
      post "widgets/validation", to: "widgets#validation"
      post "widgets/conflict", to: "widgets#conflict"
      post "widgets/boom", to: "widgets#boom"
      get "widgets/not_found", to: "widgets#not_found"
    end
  end
end
