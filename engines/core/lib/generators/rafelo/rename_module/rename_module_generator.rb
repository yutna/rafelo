# frozen_string_literal: true

require "rails/generators"
require "yaml"

module Rafelo
  module Generators
    class RenameModuleGenerator < Rails::Generators::Base
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

      def validate!
        raise Thor::Error, "engine not found: #{@source_name}" unless Dir.exist?(root.join("engines", @source_name))
        raise Thor::Error, "engine already exists: #{@destination_name}" if Dir.exist?(root.join("engines", @destination_name))
        raise Thor::Error, "reserved name: #{@destination_name}" if %w[core design_system app engines].include?(@destination_name) || @destination_name.start_with?("example_") || !@destination_name.match?(/\A[a-z][a-z0-9_]*\z/)
      end

      def perform_rename
        source = root.join("engines", @source_name)
        target = root.join("engines", @destination_name)
        FileUtils.mv(source, target)

        rename_if_exists(target.join("rafelo_#{@source_name}.gemspec"), target.join("rafelo_#{@destination_name}.gemspec"))
        rename_if_exists(target.join("lib/rafelo_#{@source_name}.rb"), target.join("lib/rafelo_#{@destination_name}.rb"))

        [
          [ "lib/rafelo", @source_name, @destination_name ],
          [ "app/controllers/rafelo", @source_name, @destination_name ],
          [ "app/policies/rafelo", @source_name, @destination_name ],
          [ "app/props/rafelo", @source_name, @destination_name ],
          [ "app/forms/rafelo", @source_name, @destination_name ],
          [ "app/public/rafelo", @source_name, @destination_name ]
        ].each do |base, from_name, to_name|
          from = target.join(base, from_name)
          to = target.join(base, to_name)
          FileUtils.mv(from, to) if Dir.exist?(from)
        end

        old_camel = @source_name.camelize
        new_camel = @destination_name.camelize
        Dir[target.join("**/*")].select { |p| File.file?(p) }.each do |path|
          body = File.binread(path)
          next if body.include?("\x00")

          body = body.gsub("Rafelo::#{old_camel}", "Rafelo::#{new_camel}")
          body = body.gsub(/\bmodule #{Regexp.escape(old_camel)}\b/, "module #{new_camel}")
          body = body.gsub(/\bclass #{Regexp.escape(old_camel)}\b/, "class #{new_camel}")
          body = body.gsub("rafelo_#{@source_name}", "rafelo_#{@destination_name}")
          body = body.gsub("rafelo/#{@source_name}", "rafelo/#{@destination_name}")
          body = body.gsub("@#{@source_name}/", "@#{@destination_name}/")
          body = body.gsub(/^(\s*)key:\s*:#{Regexp.escape(@source_name)}\b/, "\\1key: :#{@destination_name}")
          # keep URL/path and permission prefixes stable per GEN-06
          if path.to_s.end_with?("config/module.rb")
            body = body.gsub(/^(\s*)path:\s*"[^"]*"/, "\\1path: \"/#{@source_name}\"")
            body = body.gsub(/^(\s*)permission_prefixes:\s*\[[^\]]*\]/, "\\1permission_prefixes: [ \"#{@source_name}\" ]")
            body = body.gsub(/^(\s*label_key:\s*)"#{Regexp.escape(@source_name)}\.nav\.title"/, "\\1\"#{@destination_name}.nav.title\"")
          end
          body = body.gsub(/^(\s*)#{Regexp.escape(@source_name)}:\s*$/, "\\1#{@destination_name}:") if path.to_s.end_with?(".yml")
          body = body.gsub(/\.nav\.title:\s*"#{Regexp.escape(@source_name.humanize)}"/, ".nav.title: \"#{@destination_name.humanize}\"")
          File.binwrite(path, body)
        end

        update_locale_keys(target)
        update_permissions_manifest(target)
        update_root_spec_paths if Dir.exist?(root.join("spec/requests", @source_name))
        update_dependents
        update_package_metadata(target)
        write_legacy_constants(target)
        update_ratchets(target)
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
        old_camel = @source_name.camelize
        new_camel = @destination_name.camelize
        lines = []
        lines << "# frozen_string_literal: true"
        lines << ""
        lines << "# Kept for one release after renaming #{@source_name} to #{@destination_name} (GEN-06)."
        lines << "module Rafelo"
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

      def update_locale_keys(engine_root)
        Dir[engine_root.join("config/locales/*.yml")].each do |path|
          content = YAML.safe_load(File.read(path), aliases: false) || {}
          next unless content.is_a?(Hash)

          locale = content.keys.first
          next unless locale && content[locale].is_a?(Hash) && content[locale].key?(@source_name)

          content[locale][@destination_name] = content[locale].delete(@source_name)
          File.write(path, YAML.dump(content))
        end
      end

      def update_permissions_manifest(engine_root)
        path = engine_root.join("config/permissions.yml")
        return unless File.file?(path)

        content = YAML.safe_load(File.read(path), aliases: false) || {}
        if content.key?(@source_name)
          content[@destination_name] = content.delete(@source_name)
          File.write(path, YAML.dump(content))
        end
      end

      def update_root_spec_paths
        from = root.join("spec/requests", @source_name)
        to = root.join("spec/requests", @destination_name)
        return unless Dir.exist?(from)

        FileUtils.mkdir_p(to.dirname)
        FileUtils.mv(from, to)
        Dir[to.join("**/*")].select { |p| File.file?(p) }.each do |path|
          body = File.read(path)
          # URLs stay stable on rename (module path is preserved), but page/component keys follow the engine name.
          body = body.gsub(%("#{ @source_name }/"), %("#{ @destination_name }/))
          File.write(path, body)
        end
      end

      def update_dependents
        Dir[root.join("engines/*/package.yml")].each do |path|
          next if path == root.join("engines", @destination_name, "package.yml").to_s

          body = File.read(path)
          next unless body.include?("engines/#{@source_name}")

          File.write(path, body.gsub("engines/#{@source_name}", "engines/#{@destination_name}"))
        end
      end

      def post_write
        inside(root) do
          %w[bundle\ install script/ci/engine_graph npm\ run\ aliases:generate npm\ run\ permissions:generate npm\ run\ errors:generate npm\ run\ i18n:generate npm\ run\ contracts:generate].each do |cmd|
            raise Thor::Error, "post-write step failed: #{cmd}" unless run(cmd)
          end
        end
      end

      def snapshot
        paths = Dir[root.join("**/*")].select { |p| File.file?(p) }
        paths.to_h { |p| [ p, File.binread(p) ] }
      end

      def restore_snapshot(before)
        after = Dir[root.join("**/*")].select { |p| File.file?(p) }
        (after - before.keys).each { |p| FileUtils.rm_f(p) }
        before.each { |p, content| File.binwrite(p, content) unless File.file?(p) && File.binread(p) == content }
        Dir[root.join("**/*")].select { |p| File.directory?(p) }.sort_by(&:length).reverse_each do |dir|
          Dir.rmdir(dir) if (Dir.entries(dir) - %w[. ..]).empty?
        end
      rescue StandardError
        nil
      end
    end
  end
end
