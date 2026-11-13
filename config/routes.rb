Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  post "core/client_errors", to: "core/client_errors#create"

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  scope ":locale", locale: Rafelo::Core::Locales.route_constraint do
    Rafelo::Core::Modules.each do |mod|
      mount mod.engine => mod.path, as: mod.route_name
    end

    get "sign_in", to: "sessions#new"
    post "sign_in", to: "sessions#create"
    delete "sign_out", to: "sessions#destroy"
    delete "sign_out_everywhere", to: "sessions#destroy_all"

    if Rails.env.test?
      require Rails.root.join("engines/core/spec/dummy_engine/lib/dummy_engine")
      mount DummyEngine::Engine => "/dummy", as: :dummy
    end

    root "home#show"

    if Rails.env.local?
      get "component_catalog", to: "component_catalog#index"
    end
  end
end
