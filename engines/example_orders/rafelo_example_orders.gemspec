require_relative "lib/rafelo/example_orders/version"

Gem::Specification.new do |spec|
  spec.name = "rafelo_example_orders"
  spec.version = Rafelo::ExampleOrders::VERSION
  spec.authors = [ "Yutthana Siphuengchai" ]
  spec.summary = "Rafelo example orders module"
  spec.description = "The example_orders product module of the Rafelo BFF template."
  spec.license = "MIT"
  spec.files = Dir["lib/**/*", "app/**/*", "config/**/*", "db/**/*", "package.yml"]
  spec.require_paths = [ "lib" ]
end
