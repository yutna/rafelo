# frozen_string_literal: true

require "rails/engine"

module Rafelo
  module Core
    class Engine < ::Rails::Engine
      isolate_namespace Rafelo::Core
    end
  end
end
