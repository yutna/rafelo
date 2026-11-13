# frozen_string_literal: true

require_relative "../base/base_generator"

module Rafelo
  module Generators
    class ModuleGenerator < BaseGenerator
      source_root File.expand_path("templates", __dir__)
      class_option :icon, type: :string, default: "folder"

      def create_module
        validate_name!
        raise Thor::Error, "icon must be one of #{icon_names.join(", ")}" unless icon_names.include?(options[:icon])

        with_rollback do
          write_engine
          write_package
          write_guides
          write_config
          write_frontend
          write_tests
          post_write unless options[:skip_post_write]
        end
        say "Created #{engine_dir} and regenerated the graph, aliases, contracts and catalogs.", :green
      end

      private

      def write_engine
        create_file "#{engine_dir}/#{gemspec_name}.gemspec", <<~RUBY
          require_relative "lib/rafelo/#{name}/version"

          Gem::Specification.new do |spec|
            spec.name = "#{gemspec_name}"
            spec.version = Rafelo::#{module_name}::VERSION
            spec.authors = [ "Yutthana Siphuengchai" ]
            spec.summary = "Rafelo #{name} module"
            spec.description = "The #{name} product module of the Rafelo BFF template."
            spec.license = "MIT"
            spec.files = Dir["lib/**/*", "app/**/*", "config/**/*", "db/**/*", "package.yml"]
            spec.require_paths = [ "lib" ]
          end
        RUBY
        create_file "#{engine_dir}/lib/rafelo/#{name}/version.rb", <<~RUBY
          # frozen_string_literal: true

          module Rafelo
            module #{module_name}
              VERSION = "0.1.0"
            end
          end
        RUBY
        create_file "#{engine_dir}/lib/rafelo_#{name}.rb", "require \"rafelo/#{name}/engine\"\n"
        create_file "#{engine_dir}/lib/rafelo/#{name}/engine.rb", <<~RUBY
          # frozen_string_literal: true

          require "rails/engine"
          require "rafelo_core"

          module #{namespace}
            module #{module_name}
              class Engine < ::Rails::Engine
                isolate_namespace #{namespace}::#{module_name}

                initializer "rafelo_#{name}.migration_paths" do |app|
                  config.paths["db/migrate"].expanded.each { |path| app.config.paths["db/migrate"] << path }
                end


              end
            end
          end
        RUBY
      end

      def write_package
        create_file "#{engine_dir}/package.yml", <<~YAML
          enforce_dependencies: strict
          enforce_privacy: strict
          public_path: app/public/
          dependencies:
            - engines/core
            - engines/design_system
        YAML
        create_file "#{engine_dir}/app/frontend/public/index.ts", "export const MODULE_NAME = \"#{name}\";\n"
        create_file "#{engine_dir}/config/routes.rb", <<~RUBY
          # frozen_string_literal: true

          #{namespace}::#{module_name}::Engine.routes.draw do
          end
        RUBY
        create_file "#{engine_dir}/config/module.rb", <<~RUBY
          # frozen_string_literal: true

          Rafelo::Core::Modules.register(
            key: :#{name},
            engine: #{namespace}::#{module_name}::Engine,
            path: "/#{name}",
            permission_prefixes: [ "#{name}" ],
            nav: { order: Rafelo::Core::Modules.all.map { |entry| entry.nav[:order] }.compact.max.to_i + 10, label_key: "#{name}.nav.title", icon: "#{options[:icon]}" }
          )
        RUBY
      end

      def write_guides
        create_file "#{engine_dir}/AGENTS.md", <<~MD
          # #{module_name} module

          Read the root AGENTS.md first. This module follows the app layering:
          pages render one screen, containers own hooks and state, components
          stay presentational, domain/ and forms/ are framework-free, and all
          user-facing copy lives in config/locales.
        MD
      end

      def write_config
        locales.each do |locale|
          create_file "#{engine_dir}/config/locales/#{locale}.yml", "#{locale}:\n  #{name}:\n    nav:\n      title: \"#{name.humanize}\"\n"
        end
        create_file "#{engine_dir}/config/errors.yml", "{}\n"
        create_file "#{engine_dir}/config/permissions.yml", "#{name}:\n  widget: [read]\n"
        create_file "#{engine_dir}/config/budgets.yml", "pages: {}\n"
        create_file "#{engine_dir}/config/ratchets.yml", "eslint_disable: 0\nuse_no_memo: 0\n"
        create_file "#{engine_dir}/config/contracts/.keep", ""
        create_file "#{engine_dir}/db/migrate/.keep", ""
        create_file "#{engine_dir}/app/public/#{namespace.downcase}/#{name}/.keep", ""
        create_file "#{engine_dir}/spec/fixtures/upstream/.keep", ""
        create_file "#{engine_dir}/e2e/.keep", ""
      end

      def write_frontend
        %w[pages screens containers components hooks domain forms].each do |dir|
          create_file "#{engine_dir}/app/frontend/#{dir}/.keep", ""
        end
      end

      def write_tests
        create_file "#{engine_dir}/app/frontend/components/skeleton.test.tsx", <<~TSX
          import "@testing-library/jest-dom/vitest";
          import { render, screen } from "@testing-library/react";
          import { describe, expect, it } from "vitest";

          describe("#{name} skeleton", () => {
            it("renders", () => {
              render(<div data-testid="#{name}.skeleton" />);
              expect(screen.getByTestId("#{name}.skeleton")).toBeInTheDocument();
            });
          });
        TSX
        create_file "#{engine_dir}/app/frontend/domain/skeleton.test.ts", <<~TS
          import { describe, expect, it } from "vitest";

          describe("#{name} domain skeleton", () => {
            it("runs without a DOM", () => {
              expect(true).toBe(true);
            });
          });
        TS
        create_file "#{engine_dir}/vitest.config.mts", <<~TS
          import react from "@vitejs/plugin-react";
          import { defineConfig } from "vitest/config";
          import { fileURLToPath } from "node:url";
          import { engineAliases } from "../../config/frontend_aliases.mts";

          const setupFiles = [fileURLToPath(new URL("../../vitest.setup.ts", import.meta.url))];

          export default defineConfig({
            plugins: [react()],
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
      end

      def gemspec_name
        "rafelo_#{name}"
      end

      def namespace
        Rails.application.class.module_parent_name
      end

      def icon_names
        File.read(Rails.root.join("engines/design_system/app/frontend/icon.tsx")).scan(/^  ([a-z_]+):/).flatten
      end

      def locales
        Rafelo::Core::Locales.available.map(&:to_s)
      end
    end
  end
end
