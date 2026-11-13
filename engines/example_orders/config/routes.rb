# frozen_string_literal: true

Rafelo::ExampleOrders::Engine.routes.draw do
  resources :orders, only: %i[index show new create edit update]
  post "orders/export", to: "orders#export", as: :export_orders
  root to: "orders#index"
end
