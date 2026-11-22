# frozen_string_literal: true

require_relative "../base/base_generator"

module Rafelo
  module Generators
    class DomainGenerator < BaseGenerator
      def create_domain
        validate_name!

        with_rollback do
          create_file "#{engine_dir}/#{gemspec_name}.gemspec", <<~RUBY
            require_relative "lib/#{app_ns_underscore}/#{name}/version"

            Gem::Specification.new do |spec|
              spec.name = "#{gemspec_name}"
              spec.version = #{namespace}::#{module_name}::VERSION
              spec.authors = [ "Yutthana Siphuengchai" ]
              spec.summary = "Rafelo #{name} domain"
              spec.description = "The #{name} domain engine of the Rafelo BFF template."
              spec.license = "MIT"
              spec.files = Dir["lib/**/*", "app/**/*", "config/**/*", "package.yml"]
              spec.require_paths = [ "lib" ]
            end
          RUBY
          create_file "#{engine_dir}/lib/#{app_ns_underscore}/#{name}/version.rb", "module #{namespace}\n  module #{module_name}\n    VERSION = \"0.1.0\"\n  end\nend\n"
          create_file "#{engine_dir}/lib/#{app_ns_underscore}_#{name}.rb", "require \"#{app_ns_underscore}/#{name}/engine\"\n"
          create_file "#{engine_dir}/lib/#{app_ns_underscore}/#{name}/engine.rb", <<~RUBY
            # frozen_string_literal: true

            require "rails/engine"

            module #{namespace}
              module #{module_name}
                class Engine < ::Rails::Engine
                  isolate_namespace #{namespace}::#{module_name}
                end
              end
            end
          RUBY
          create_file "#{engine_dir}/package.yml", "enforce_dependencies: strict\nenforce_privacy: strict\npublic_path: app/public/\ndependencies:\n  - engines/core\n  - engines/design_system\n"
          create_file "#{engine_dir}/AGENTS.md", <<~MD
            # #{module_name} domain

            Read the root AGENTS.md first. A domain engine holds one business
            concept several products share. Keep `domain/` and `forms/`
            framework-free (no React, Inertia, i18next, or design_system); use a
            hook to bridge them into presentational components. `app/public/` and
            `app/frontend/public/` are the only files other engines may import
            (ARCH-09). It has no routes, pages, navigation, registry entry,
            budgets, or permission prefix (GEN-05).
          MD
          create_file "#{engine_dir}/app/public/#{app_ns_underscore}/#{name}/.keep", ""
          create_file "#{engine_dir}/app/frontend/public/index.ts", "export const DOMAIN_NAME = \"#{name}\";\n"
          create_file "#{engine_dir}/app/frontend/domain/.keep", ""
          create_file "#{engine_dir}/app/frontend/forms/.keep", ""
          create_file "#{engine_dir}/app/frontend/hooks/.keep", ""
          create_file "#{engine_dir}/app/frontend/components/.keep", ""
          create_file "#{engine_dir}/app/frontend/domain/skeleton.test.ts", "import { describe, expect, it } from \"vitest\";\n\ndescribe(\"#{name} domain\", () => {\n  it(\"runs without a DOM\", () => expect(true).toBe(true));\n});\n"
          create_file "#{engine_dir}/app/frontend/components/skeleton.test.tsx", "import \"@testing-library/jest-dom/vitest\";\nimport { render, screen } from \"@testing-library/react\";\nimport { describe, expect, it } from \"vitest\";\n\ndescribe(\"#{name} component\", () => {\n  it(\"renders\", () => {\n    render(<div data-testid=\"#{name}.skeleton\" />);\n    expect(screen.getByTestId(\"#{name}.skeleton\")).toBeInTheDocument();\n  });\n});\n"
          create_file "#{engine_dir}/config/contracts/.keep", ""
          create_file "#{engine_dir}/config/errors.yml", "{}\n"
          create_file "#{engine_dir}/config/ratchets.yml", <<~YAML
            eslint_disable: 0
            rubocop_disable: 0
            use_no_memo: 0
            skipped_tests: 0
            page_budget_overrides: 0
            legacy_table_prefixes: 0
            legacy_constants: 0
          YAML
          create_file "#{engine_dir}/db/migrate/.keep", ""
          create_file "#{engine_dir}/spec/rails_helper.rb", "require_relative \"../../../spec/rails_helper\"\n"
          create_file "#{engine_dir}/spec/fixtures/upstream/.keep", ""
          create_file "#{engine_dir}/e2e/.keep", ""
          Rafelo::Core::Locales.available.map(&:to_s).each do |locale|
            create_file "#{engine_dir}/config/locales/#{locale}.yml", "#{locale}:\n  #{name}:\n    nav:\n      title: \"#{name.humanize}\"\n"
          end
          create_file "#{engine_dir}/vitest.config.mts", <<~TS
            import { defineConfig } from "vitest/config";
            import { fileURLToPath } from "node:url";
            import { engineAliases } from "../../config/frontend_aliases.mts";
            import { reactPlugins } from "../../config/frontend_react.mts";

            const setupFiles = [fileURLToPath(new URL("../../vitest.setup.ts", import.meta.url))];

            export default defineConfig({
              plugins: reactPlugins(),
              resolve: { alias: engineAliases },
              test: {
                projects: [
                  {
                    test: {
                      name: "#{name}",
                      environment: "jsdom",
                      include: ["app/frontend/**/*.test.tsx", "app/frontend/**/hooks/**/*.test.ts"],
                      setupFiles,
                    },
                  },
                  {
                    test: {
                      name: "#{name}:node",
                      environment: "node",
                      include: ["app/frontend/**/*.test.ts"],
                      exclude: ["app/frontend/**/hooks/**"],
                    },
                  },
                ],
              },
            });
          TS
          post_write unless options[:skip_post_write]
        end
        say "Created #{engine_dir}.", :green
      end

      private

      def gemspec_name
        "#{app_ns_underscore}_#{name}"
      end

      def namespace
        Rails.application.class.module_parent_name
      end

      def app_ns_underscore
        namespace.gsub(/([a-z\d])([A-Z])/, '\\1_\\2').downcase
      end
    end
  end
end
