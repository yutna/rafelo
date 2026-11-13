# frozen_string_literal: true

require "rails/generators"
require "json"

module Rafelo
  module Generators
    class BaseGenerator < Rails::Generators::NamedBase
      RESERVED = %w[core design_system app engines].freeze unless const_defined?(:RESERVED)

      def validate_name!
        candidate = name.to_s.underscore
        raise Thor::Error, "name is required" if candidate.blank?
        raise Thor::Error, "#{candidate} is reserved" if RESERVED.include?(candidate)
        raise Thor::Error, "#{candidate} must not start with example_" if candidate.start_with?("example_")
        raise Thor::Error, "#{candidate} is not a snake_case engine name" unless candidate.match?(/\A[a-z][a-z0-9_]*\z/)
        raise Thor::Error, "#{candidate} is already taken" if Dir.exist?(Rails.root.join("engines", candidate))
        raise Thor::Error, "npm scope @#{candidate} is already used" if npm_scopes.include?(candidate)
        raise Thor::Error, "#{candidate} is a locale" if locale_segments.include?(candidate) || candidate.match?(/\A[a-z]{2}\z/)
        raise Thor::Error, "#{candidate} is an app route" if route_names.include?(candidate)
        raise Thor::Error, "#{candidate} is a kernel error prefix" if error_prefixes.include?(candidate)
      end

      def module_name
        name.to_s.camelize
      end

      class_option :skip_post_write, type: :boolean, default: false

      def name
        super.to_s.underscore
      end

      def engine_dir
        "engines/#{name}"
      end

      private

      def with_rollback
        engine = Rails.root.join("engines", name.to_s.underscore)
        before = generated_tree_state
        yield
      rescue StandardError => error
        FileUtils.rm_rf(engine)
        restore_tree(before)
        raise Thor::Error, "generator rolled back after: #{error.message}"
      end

      def generated_tree_state
        files = %w[
          .dependency-cruiser.engines.generated.json Gemfile.lock tsconfig.json tsconfig.base.json
          tsconfig.tooling.json app/frontend/tsconfig.json config/frontend_aliases.mts
        ]
        files.to_h { |path| [ path, File.file?(Rails.root.join(path)) ? File.binread(Rails.root.join(path)) : nil ] }
      end

      def restore_tree(before)
        before.each do |path, content|
          target = Rails.root.join(path)
          if content.nil?
            FileUtils.rm_f(target)
          else
            File.binwrite(target, content)
          end
        end
      end

      def post_write
        inside(Rails.root) do
          run_step "bundle install"
          run_step "script/ci/engine_graph"
          run_step "npm run aliases:generate"
          run_step "npm run i18n:generate"
          run_step "npm run errors:generate"
          run_step "npm run permissions:generate"
          run_step "npm run contracts:generate"
        end
      end

      def run_step(command)
        raise Thor::Error, "generator step failed: #{command}" unless run(command)
      end

      def npm_scopes
        package = JSON.parse(File.read(Rails.root.join("package.json")))
        package.fetch("dependencies", {}).merge(package.fetch("devDependencies", {})).keys.filter_map { |key| key[%r{\A@([^/]+)/}, 1] }
      end

      def locale_segments
        Rafelo::Core::Locales.available.map(&:to_s)
      end

      def route_names
        routes = Rails.application.routes.routes
        names = routes.filter_map(&:name).map(&:to_s)
        segments = routes.filter_map { |route| route.path.spec.to_s[%r{\A/([a-z][a-z0-9_]*)}, 1] }
        names + segments
      end

      def error_prefixes
        YAML.load_file(Rails.root.join("config/errors.yml")).keys.map { |key| key.split(".").first }
      end
    end
  end
end
