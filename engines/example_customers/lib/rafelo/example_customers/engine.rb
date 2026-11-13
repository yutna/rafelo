# frozen_string_literal: true

require "rails/engine"

module Rafelo
  module ExampleCustomers
    class Engine < ::Rails::Engine
      isolate_namespace Rafelo::ExampleCustomers
    end
  end
end
