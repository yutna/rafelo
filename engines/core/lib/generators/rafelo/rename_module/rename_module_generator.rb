# frozen_string_literal: true

require "rails/generators"
require "yaml"
require_relative "../base/grant_catalog"
require_relative "../base/post_write"

module Rafelo
  module Generators
    class RenameModuleGenerator < Rails::Generators::Base
      include PostWrite

      argument :old_name, type: :string
      argument :target_name, type: :string
      class_option :skip_post_write, type: :boolean, default: false

      def rename
        @source_name = old_name.to_s.underscore
        @destination_name = target_name.to_s.underscore
        @root = Pathname.new(destination_root || Dir.pwd)
        validate!
        @snapshot = snapshot
        perform_rename
        post_write unless options[:skip_post_write]
        say "Renamed #{@source_name} to #{@destination_name}.", :green
      rescue StandardError => e
        restore_snapshot(@snapshot) if defined?(@snapshot)
        raise Thor::Error, "generator rolled back after: #{e.message}"
      end

      private

      attr_reader :root

      def app_namespace = Rails.application.class.module_parent_name
      def app_ns_underscore = app_namespace.gsub(/([a-z\d])([A-Z])/, '\\1_\\2').downcase
      def old_camel = @source_name.camelize
      def new_camel = @destination_name.camelize

      def validate!
        raise Thor::Error, "engine not found: #{@source_name}" unless Dir.exist?(root.join("engines", @source_name))
        raise Thor::Error, "engine already exists: #{@destination_name}" if Dir.exist?(root.join("engines", @destination_name))
        raise Thor::Error, "reserved name: #{@destination_name}" if %w[core design_system app engines].include?(@destination_name) || @destination_name.start_with?("example_") || !@destination_name.match?(/\A[a-z][a-z0-9_]*\z/)
      end

      def perform_rename
        source = root.join("engines", @source_name)
        target = root.join("engines", @destination_name)
        FileUtils.mv(source, target)

        rename_engine_entry_points(target)
        move_namespaced_directories(target)
        rewrite_engine_files(target)
        update_locale_keys(target)
        update_root_spec_paths
        update_root_e2e
        update_external_references
        update_dependents
        update_package_metadata(target)
        write_legacy_constants(target)
        update_ratchets(target)
      end

      def rename_engine_entry_points(target)
        rename_if_exists(
          target.join("#{app_ns_underscore}_#{@source_name}.gemspec"),
          target.join("#{app_ns_underscore}_#{@destination_name}.gemspec")
        )
        rename_if_exists(
          target.join("lib/#{app_ns_underscore}_#{@source_name}.rb"),
          target.join("lib/#{app_ns_underscore}_#{@destination_name}.rb")
        )
      end

      def move_namespaced_directories(target)
        [
          "lib/#{app_ns_underscore}",
          "app/controllers/#{app_ns_underscore}",
          "app/policies/#{app_ns_underscore}",
          "app/props/#{app_ns_underscore}",
          "app/forms/#{app_ns_underscore}",
          "app/public/#{app_ns_underscore}"
        ].each do |base|
          from = target.join(base, @source_name)
          to = target.join(base, @destination_name)
          FileUtils.mv(from, to) if Dir.exist?(from)
        end
      end

      def rewrite_engine_files(target)
        Dir[target.join("**/*")].select { |path| File.file?(path) }.each do |path|
          rewrite_file(path, module_manifest: path.to_s.end_with?("config/module.rb"))
        end
      end

      def rewrite_file(path, module_manifest: false)
        body = File.binread(path)
        return if body.include?("\x00")

        changed = body.gsub(old_camel, new_camel)
        changed = changed.gsub("#{app_ns_underscore}/#{@source_name}", "#{app_ns_underscore}/#{@destination_name}")
        changed = changed.gsub("@#{@source_name}/", "@#{@destination_name}/")
        changed = changed.gsub("engines/#{@source_name}/", "engines/#{@destination_name}/")
        changed = changed.gsub(/:#{Regexp.escape(@source_name)}\b/, ":#{@destination_name}")
        changed = changed.gsub(/(?<![\/@\w])#{Regexp.escape(@source_name)}\//, "#{@destination_name}/")
        # Test ids, i18n keys, and error codes use dot-separated namespaces; a
        # leading slash is a URL and keeps its old path (GEN-06).
        changed = changed.gsub(/(?<![\/\w])#{Regexp.escape(@source_name)}\./, "#{@destination_name}.")
        unless module_manifest
          changed = changed.gsub("\"#{@source_name}\"", "\"#{@destination_name}\"")
          changed = changed.gsub("'#{@source_name}'", "'#{@destination_name}'")
        end
        if File.basename(path) == "vitest.config.mts"
          changed = changed.gsub("\"#{@source_name}:node\"", "\"#{@destination_name}:node\"")
          changed = changed.gsub("'#{@source_name}:node'", "'#{@destination_name}:node'")
        end
        if documentation_file?(path) || generated_path_file?(path)
          changed = changed.gsub(@source_name, @destination_name)
        end
        File.binwrite(path, changed) if changed != body
      end

      def documentation_file?(path)
        %w[AGENTS.md README.md].include?(File.basename(path)) || path.to_s.end_with?(".gemspec")
      end

      def generated_path_file?(path)
        File.basename(path) == "tsconfig.json"
      end

      def update_locale_keys(engine_root)
        Dir[engine_root.join("config/locales/*.yml")].each do |path|
          content = YAML.safe_load(File.read(path), aliases: false) || {}
          next unless content.is_a?(Hash)

          locale = content.keys.first
          next unless locale && content[locale].is_a?(Hash) && content[locale].key?(@source_name)

          content[locale][@destination_name] = content[locale].delete(@source_name)
          nav = content[locale][@destination_name]["nav"]
          if nav.is_a?(Hash) && nav["title"] == @source_name.humanize
            nav["title"] = @destination_name.humanize
          end
          File.write(path, YAML.dump(content))
        end
      end

      def update_root_spec_paths
        from = root.join("spec/requests", @source_name)
        to = root.join("spec/requests", @destination_name)
        return unless Dir.exist?(from)

        FileUtils.mkdir_p(to.dirname)
        FileUtils.mv(from, to)
        Dir[to.join("**/*")].select { |path| File.file?(path) }.each do |path|
          body = File.read(path)
          # URLs and permission keys stay stable on rename (GEN-06); page keys
          # and engine paths follow the new module name.
          body = body.gsub(/(?<![\/@\w])#{Regexp.escape(@source_name)}\//, "#{@destination_name}/")
          body = body.gsub("engines/#{@source_name}/", "engines/#{@destination_name}/")
          body = body.gsub("@#{@source_name}/", "@#{@destination_name}/")
          body = body.gsub(old_camel, new_camel)
          File.write(path, body)
        end
      end

      def update_root_e2e
        from = root.join("e2e", @source_name)
        to = root.join("e2e", @destination_name)
        return unless Dir.exist?(from)

        FileUtils.mv(from, to)
        Dir[to.join("**/*")].select { |path| File.file?(path) }.each do |path|
          rewrite_file(path)
        end
      end

      def update_external_references
        patterns = [
          "app/**/*.{rb,ts,tsx,mts,json}",
          "engines/*/**/*.{rb,ts,tsx,mts,json}",
          "spec/**/*.{rb,ts,tsx,mts}",
          "e2e/**/*.{ts,tsx,mts}",
          "config/*.mts"
        ]
        files = patterns.flat_map { |pattern| Dir[root.join(pattern)] }.uniq
        files.each do |path|
          next unless File.file?(path)
          next if path.start_with?(root.join("engines", @destination_name).to_s + "/")

          rewrite_external_file(path)
        end
      end

      def rewrite_external_file(path)
        body = File.binread(path)
        return if body.include?("\x00")

        changed = body.gsub(old_camel, new_camel)
        changed = changed.gsub("@#{@source_name}/", "@#{@destination_name}/")
        changed = changed.gsub("\"@#{@source_name}\"", "\"@#{@destination_name}\"")
        changed = changed.gsub("'@#{@source_name}'", "'@#{@destination_name}'")
        changed = changed.gsub("engines/#{@source_name}/", "engines/#{@destination_name}/")
        File.binwrite(path, changed) if changed != body
      end

      def update_dependents
        Dir[root.join("engines/*/package.yml")].each do |path|
          next if path == root.join("engines", @destination_name, "package.yml").to_s

          body = File.read(path)
          next unless body.include?("engines/#{@source_name}")

          body = body.gsub(
            /^(\s*-\s*)engines\/#{Regexp.escape(@source_name)}\s*$/,
            "\\1engines/#{@destination_name}"
          )
          File.write(path, body)
        end
      end

      def update_package_metadata(engine_root)
        path = engine_root.join("package.yml")
        return unless File.file?(path)

        data = YAML.safe_load(File.read(path), aliases: false) || {}
        metadata = (data["metadata"] || {}).dup
        metadata["legacy_table_prefix"] = @source_name unless metadata.key?("legacy_table_prefix")
        data["metadata"] = metadata
        File.write(path, YAML.dump(data))
      end

      def write_legacy_constants(engine_root)
        path = engine_root.join("config/initializers/legacy_constants.rb")
        FileUtils.mkdir_p(File.dirname(path))
        lines = []
        lines << "# frozen_string_literal: true"
        lines << ""
        lines << "# Kept for one release after renaming #{@source_name} to #{@destination_name} (GEN-06)."
        lines << "module #{app_namespace}"
        lines << "  #{old_camel} = #{new_camel} unless const_defined?(:#{old_camel}, false)"
        lines << "end"
        File.write(path, lines.join("\n") + "\n")
      end

      def update_ratchets(engine_root)
        path = engine_root.join("config/ratchets.yml")
        return unless File.file?(path)

        data = YAML.safe_load(File.read(path), aliases: false) || {}
        data["legacy_table_prefixes"] = data.fetch("legacy_table_prefixes", 0).to_i + 1
        data["legacy_constants"] = data.fetch("legacy_constants", 0).to_i + 1
        File.write(path, YAML.dump(data))
      end

      def rename_if_exists(from, to)
        FileUtils.mv(from, to) if File.exist?(from)
      end

      def post_write
        Rafelo::Generators::GrantCatalog.sync(root)
        run_post_write(root: root, formatter_files: formatted_files)
      end

      def formatted_files
        engine = root.join("engines", @destination_name)
        files = Dir[engine.join("app/frontend/**/*.{ts,tsx,mts,json}")]
          .concat([ engine.join("package.yml"), engine.join("config/ratchets.yml") ])
          .select { |p| File.file?(p) }
          .map(&:to_s)
          .reject { |p| p.end_with?(".generated.ts") || p.end_with?(".generated.tsx") || p.include?("/app/frontend/locales/") }
        files.uniq
      end

      def snapshot
        paths = Dir[root.join("**/*")].select { |p| File.file?(p) }
        paths.to_h { |p| [ p, File.binread(p) ] }
      end

      def restore_snapshot(before)
        after = Dir[root.join("**/*")].select { |p| File.file?(p) }
        (after - before.keys).each { |p| FileUtils.rm_f(p) }
        before.each do |p, content|
          FileUtils.mkdir_p(File.dirname(p))
          File.binwrite(p, content) unless File.file?(p) && File.binread(p) == content
        end
        Dir[root.join("**/*")].select { |p| File.directory?(p) }.sort_by(&:length).reverse_each do |dir|
          Dir.rmdir(dir) if (Dir.entries(dir) - %w[. ..]).empty?
        rescue StandardError
          nil
        end
      rescue StandardError
        nil
      end
    end
  end
end
