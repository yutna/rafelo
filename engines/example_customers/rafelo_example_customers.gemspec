require_relative "lib/rafelo/example_customers/version"

Gem::Specification.new do |spec|
  spec.name = "rafelo_example_customers"
  spec.version = Rafelo::ExampleCustomers::VERSION
  spec.authors = [ "Yutthana Siphuengchai" ]
  spec.summary = "Rafelo example customers domain"
  spec.description = "The example_customers domain engine of the Rafelo BFF template."
  spec.license = "MIT"
  spec.files = Dir["lib/**/*", "app/**/*", "config/**/*", "package.yml"]
  spec.require_paths = [ "lib" ]
end
