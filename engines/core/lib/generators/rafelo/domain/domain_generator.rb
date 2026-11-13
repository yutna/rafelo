# frozen_string_literal: true

require_relative "../base/base_generator"

module Rafelo
  module Generators
    class DomainGenerator < BaseGenerator
      def create_domain
        validate_name!

        with_rollback do
          create_file "#{engine_dir}/rafelo_#{name}.gemspec", <<~RUBY
            require_relative "lib/rafelo/#{name}/version"

            Gem::Specification.new do |spec|
              spec.name = "rafelo_#{name}"
              spec.version = Rafelo::#{module_name}::VERSION
              spec.authors = [ "Yutthana Siphuengchai" ]
              spec.summary = "Rafelo #{name} domain"
              spec.description = "The #{name} domain engine of the Rafelo BFF template."
              spec.license = "MIT"
              spec.files = Dir["lib/**/*", "app/**/*", "config/**/*", "package.yml"]
              spec.require_paths = [ "lib" ]
            end
          RUBY
          create_file "#{engine_dir}/lib/rafelo/#{name}/version.rb", "module Rafelo\n  module #{module_name}\n    VERSION = \"0.1.0\"\n  end\nend\n"
          create_file "#{engine_dir}/lib/rafelo_#{name}.rb", "require \"rafelo/#{name}/engine\"\n"
          create_file "#{engine_dir}/lib/rafelo/#{name}/engine.rb", <<~RUBY
            # frozen_string_literal: true

            require "rails/engine"

            module Rafelo
              module #{module_name}
                class Engine < ::Rails::Engine
                  isolate_namespace Rafelo::#{module_name}
                end
              end
            end
          RUBY
          create_file "#{engine_dir}/package.yml", "enforce_dependencies: strict\nenforce_privacy: strict\npublic_path: app/public/\ndependencies:\n  - engines/core\n"
          create_file "#{engine_dir}/AGENTS.md", "# #{module_name} domain\n\nFramework-free domain objects and services. No React, Rails or design-system imports.\n"
          create_file "#{engine_dir}/app/public/.keep", ""
          create_file "#{engine_dir}/app/frontend/public/index.ts", "export const DOMAIN_NAME = \"#{name}\";\n"
          create_file "#{engine_dir}/app/frontend/domain/.keep", ""
          create_file "#{engine_dir}/app/frontend/domain/skeleton.test.ts", "import { describe, expect, it } from \"vitest\";\n\ndescribe(\"#{name} domain\", () => {\n  it(\"runs without a DOM\", () => expect(true).toBe(true));\n});\n"
          post_write
        end
        say "Created #{engine_dir}.", :green
      end
    end
  end
end
