# frozen_string_literal: true

# Each module owns its registry entry in config/module.rb; the app loads them
# after engine autoload paths are ready and before routes are drawn (ARCH-06).
require Rails.root.join("engines/core/app/models/rafelo/core/modules")

Dir[Rails.root.join("engines/*/config/module.rb")].sort.each { |file| require file }
