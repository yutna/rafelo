# frozen_string_literal: true

require "rails/engine"

module Rafelo
  module DesignSystem
    class Engine < ::Rails::Engine
      isolate_namespace Rafelo::DesignSystem
    end
  end
end
