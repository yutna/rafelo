# frozen_string_literal: true

require "rails/engine"
require "rafelo_core"

module Rafelo
  module ExampleCustomers
    class Engine < ::Rails::Engine
      isolate_namespace Rafelo::ExampleCustomers

      initializer "rafelo_example_customers.migration_paths" do |app|
        config.paths["db/migrate"].expanded.each { |path| app.config.paths["db/migrate"] << path }
      end
    end
  end
end
