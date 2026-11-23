# frozen_string_literal: true

require "rails/generators"
require "json"
require "yaml"
require_relative "grant_catalog"
require_relative "post_write"

module Rafelo
  module Generators
    class BaseGenerator < Rails::Generators::NamedBase
      include PostWrite

      RESERVED = %w[core design_system app engines].freeze unless const_defined?(:RESERVED)

      def validate_name!
        candidate = name.to_s.underscore
        raise Thor::Error, "name is required" if candidate.blank?
        raise Thor::Error, "#{candidate} is reserved" if RESERVED.include?(candidate)
        raise Thor::Error, "#{candidate} must not start with example_" if candidate.start_with?("example_")
        raise Thor::Error, "#{candidate} is not a snake_case engine name" unless candidate.match?(/\A[a-z][a-z0-9_]*\z/)
        raise Thor::Error, "#{candidate} is already taken" if Dir.exist?(root_path.join("engines", candidate))
        raise Thor::Error, "npm scope @#{candidate} is already used" if npm_scopes.include?(candidate)
        raise Thor::Error, "#{candidate} is a locale" if locale_segments.include?(candidate) || Rafelo::Core::Locales.locale_segment?(candidate)
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
        before = generated_tree_state
        yield
      rescue StandardError => error
        FileUtils.rm_rf(root_path.join(engine_dir))
        restore_tree(before)
        raise Thor::Error, "generator rolled back after: #{error.message}"
      end

      def generated_tree_state
        Dir[root_path.join("**/*")].select { |path| File.file?(path) }.to_h do |path|
          [ path, File.binread(path) ]
        end
      end

      def restore_tree(before)
        after = Dir[root_path.join("**/*")].select { |path| File.file?(path) }
        (after - before.keys).each { |path| FileUtils.rm_f(path) }
        before.each do |path, content|
          next if File.file?(path) && File.binread(path) == content

          FileUtils.mkdir_p(File.dirname(path))
          File.binwrite(path, content)
        end
        prune_empty_dirs
      end

      def prune_empty_dirs
        Dir[root_path.join("**/*")].select { |path| File.directory?(path) }
          .sort_by(&:length).reverse_each do |dir|
            Dir.rmdir(dir) if (Dir.entries(dir) - %w[. ..]).empty?
          rescue StandardError
            nil
          end
      end

      def post_write
        GrantCatalog.sync(root_path)
        run_post_write(root: root_path, formatter_files: written_files)
      end

      def written_files
        Dir[root_path.join(engine_dir, "**/*")].select do |path|
          File.file?(path) && path.match?(/\.(?:json|md|mts|ts|tsx|ya?ml)\z/)
        end
      end

      def npm_scopes
        path = root_path.join("package.json")
        path = Rails.root.join("package.json") unless File.file?(path)
        package = JSON.parse(File.read(path))
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
        path = root_path.join("config/errors.yml")
        path = Rails.root.join("config/errors.yml") unless File.file?(path)
        YAML.load_file(path).keys.map { |key| key.split(".").first }
      end

      def root_path
        Pathname.new(destination_root || Dir.pwd)
      end
    end
  end
end
