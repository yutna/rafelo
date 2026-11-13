# frozen_string_literal: true

require "rails/engine"
require "rafelo_core"

module Rafelo
  module ExampleOrders
    class Engine < ::Rails::Engine
      isolate_namespace Rafelo::ExampleOrders

      initializer "rafelo_example_orders.migration_paths" do |app|
        config.paths["db/migrate"].expanded.each { |path| app.config.paths["db/migrate"] << path }
      end
    end
  end
end
