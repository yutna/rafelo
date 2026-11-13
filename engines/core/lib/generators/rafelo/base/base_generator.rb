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
        raise Thor::Error, "#{candidate} is a locale" if locale_segments.include?(candidate)
        raise Thor::Error, "#{candidate} is an app route" if route_names.include?(candidate)
        raise Thor::Error, "#{candidate} is a kernel error prefix" if error_prefixes.include?(candidate)
      end

      def module_name
        name.to_s.camelize
      end

      def engine_dir
        "engines/#{name}"
      end

      private

      def with_rollback
        before = Dir.glob(Rails.root.join("engines", name.to_s.underscore, "**/*"), File::FNM_DOTMATCH)
        yield
      rescue StandardError
        after = Dir.glob(Rails.root.join("engines", name.to_s.underscore, "**/*"), File::FNM_DOTMATCH)
        (after - before).sort.reverse_each { |path| FileUtils.rm_rf(path) }
        FileUtils.rm_rf(Rails.root.join("engines", name.to_s.underscore))
        raise
      end

      def post_write
        inside(Rails.root) do
          run "script/ci/engine_graph"
          run "npm run aliases:generate"
          run "npm run contracts:generate"
          run "npm run i18n:generate"
          run "bundle install"
        end
      end

      def npm_scopes
        package = JSON.parse(File.read(Rails.root.join("package.json")))
        package.fetch("dependencies", {}).keys.filter_map { |key| key[%r{\A@([^/]+)/}, 1] }
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
