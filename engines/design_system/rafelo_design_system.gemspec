require_relative "lib/rafelo/design_system/version"

Gem::Specification.new do |spec|
  spec.name = "rafelo_design_system"
  spec.version = Rafelo::DesignSystem::VERSION
  spec.authors = [ "Yutthana Siphuengchai" ]
  spec.summary = "Rafelo design system engine"
  spec.description = "The domain-free UI kit of the Rafelo BFF template."
  spec.license = "MIT"
  spec.files = Dir["lib/**/*", "app/**/*", "config/**/*", "package.yml"]
  spec.require_paths = [ "lib" ]
end
