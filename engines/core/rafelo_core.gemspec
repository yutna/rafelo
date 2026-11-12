require_relative "lib/rafelo/core/version"

Gem::Specification.new do |spec|
  spec.name = "rafelo_core"
  spec.version = Rafelo::Core::VERSION
  spec.authors = [ "Yutthana Siphuengchai" ]
  spec.summary = "Rafelo kernel engine"
  spec.description = "The domain-free kernel of the Rafelo BFF template."
  spec.license = "MIT"
  spec.files = Dir["lib/**/*", "app/**/*", "config/**/*", "db/**/*", "package.yml"]
  spec.require_paths = [ "lib" ]
end
