# frozen_string_literal: true

require "rails/generators"
require "yaml"

module Rafelo
  module Generators
    class MovePageGenerator < Rails::Generators::Base
      argument :source_module, type: :string
      argument :target_module, type: :string
      argument :resource, type: :string
      class_option :skip_post_write, type: :boolean, default: false

      def move
        @source = source_module.to_s.underscore
        @target = target_module.to_s.underscore
        @res = resource.to_s.underscore
        @root = Pathname.new(destination_root || Dir.pwd)
        validate!
        @snapshot = snapshot
        perform_move
        post_write unless options[:skip_post_write]
        say "Moved #{@source}/#{@res} to #{@target}/#{@res}.", :green
      rescue StandardError => e
        restore_snapshot(@snapshot) if defined?(@snapshot)
        raise Thor::Error, "generator rolled back after: #{e.message}"
      end

      private

      attr_reader :root

      def validate!
        raise Thor::Error, "source engine not found" unless Dir.exist?(root.join("engines", @source))
        raise Thor::Error, "target engine not found" unless Dir.exist?(root.join("engines", @target))
      end

      def plural = @res.pluralize
      def singular = @res.singularize

      def perform_move
        move_tree("app/frontend/pages/#{plural}", "app/frontend/pages/#{plural}")
        move_tree("app/frontend/screens/#{plural}", "app/frontend/screens/#{plural}")
        move_tree("app/frontend/containers/#{plural}", "app/frontend/containers/#{plural}")
        move_tree("app/frontend/components/#{plural}", "app/frontend/components/#{plural}")
        move_glob("app/controllers/rafelo/#{@source}", "app/controllers/rafelo/#{@target}", "*#{plural}*")
        move_glob("app/policies/rafelo/#{@source}", "app/policies/rafelo/#{@target}", "*#{singular}*")
        move_glob("app/props/rafelo/#{@source}", "app/props/rafelo/#{@target}", "*#{plural}*")
        move_glob("app/forms/rafelo/#{@source}", "app/forms/rafelo/#{@target}", "*#{singular}*")
        move_tree("config/contracts/pages/#{plural}", "config/contracts/pages/#{plural}")

        rewrite_target_contents
        move_root_request_specs
        rewrite_routes
        move_permissions
        add_legacy_path
      end

      def move_tree(from_rel, to_rel)
        from = root.join("engines", @source, from_rel)
        to = root.join("engines", @target, to_rel)
        return unless File.exist?(from)

        FileUtils.mkdir_p(File.dirname(to))
        FileUtils.mv(from, to)
      end

      def move_glob(from_dir_rel, to_dir_rel, pattern)
        from_dir = root.join("engines", @source, from_dir_rel)
        to_dir = root.join("engines", @target, to_dir_rel)
        return unless Dir.exist?(from_dir)

        FileUtils.mkdir_p(to_dir)
        Dir[from_dir.join(pattern)].each { |path| FileUtils.mv(path, to_dir.join(File.basename(path))) }
      end

      def rewrite_target_contents
        Dir[root.join("engines", @target, "**/*")].select { |p| File.file?(p) }.each do |path|
          body = File.binread(path)
          next if body.include?("\x00")

          changed = body.dup
          changed = changed.gsub("Rafelo::#{@source.camelize}", "Rafelo::#{@target.camelize}")
          changed = changed.gsub("module #{@source.camelize}", "module #{@target.camelize}") # unlikely but safe
          changed = changed.gsub("\"#{@source}/#{plural}\"", "\"#{@target}/#{plural}\"")
          changed = changed.gsub("'#{@source}/#{plural}'", "'#{@target}/#{plural}'")
          changed = changed.gsub("/#{@source}/#{plural}", "/#{@target}/#{plural}")
          changed = changed.gsub(":#{@source},", ":#{@target},")
          File.binwrite(path, changed) if changed != body
        end
      end

      def move_root_request_specs
        src = root.join("spec/requests", @source)
        dst = root.join("spec/requests", @target)
        return unless Dir.exist?(src)

        FileUtils.mkdir_p(dst)
        Dir[src.join("*#{plural}*")].each do |path|
          FileUtils.mv(path, dst.join(File.basename(path)))
        end
        Dir[dst.join("*#{plural}*")].select { |p| File.file?(p) }.each do |path|
          body = File.read(path)
          body = body.gsub("/en/#{@source}/#{plural}", "/en/#{@target}/#{plural}")
          body = body.gsub("\"#{@source}/#{plural}", "\"#{@target}/#{plural}")
          body = body.gsub("#{@source}:#{plural}", "#{@source}:#{plural}") # keep permission keys stable
          File.write(path, body)
        end
      end

      def rewrite_routes
        src_path = root.join("engines", @source, "config/routes.rb")
        src = File.read(src_path)
        moved_had_index = src.match?(/resources :#{plural}[^\n]*index/) || src.match?(/resources :#{plural}(?![^\n]*only:)/)
        moved_was_root = src.match?(/^\s*root to:\s*"#{plural}#index"/)
        src = src.gsub(/^\s*resources :#{plural}[^\n]*\n/, "")
        if moved_was_root
          next_index = src[/^\s*resources :(\w+)[^\n]*\bindex\b/, 1] || src[/^\s*resources :(\w+)(?![^\n]*only:)/, 1]
          if next_index
            src = src.sub(/^\s*root to:.*\n/, "    root to: \"#{next_index}#index\"\n")
          else
            src = src.gsub(/^\s*root to:.*\n/, "")
          end
        end
        File.write(src_path, src)

        tgt_path = root.join("engines", @target, "config/routes.rb")
        tgt = File.read(tgt_path)
        unless tgt.include?("resources :#{plural}")
          root_line = (!tgt.include?("root to:") && moved_had_index) ? "    root to: \"#{plural}#index\"\n" : ""
          tgt = tgt.sub("Engine.routes.draw do\n", "Engine.routes.draw do\n    resources :#{plural}\n#{root_line}")
        end
        File.write(tgt_path, tgt)
      end

      def move_permissions
        src_path = root.join("engines", @source, "config/permissions.yml")
        tgt_path = root.join("engines", @target, "config/permissions.yml")
        src = YAML.safe_load(File.read(src_path), aliases: false) || {}
        tgt = YAML.safe_load(File.read(tgt_path), aliases: false) || {}
        src_prefix = src[@source] || {}
        tgt_prefix = tgt[@target] || {}
        if src_prefix.key?(plural)
          tgt_prefix[plural] = src_prefix.delete(plural)
        end
        src[@source] = src_prefix
        tgt[@target] = tgt_prefix
        File.write(src_path, YAML.dump(src))
        File.write(tgt_path, YAML.dump(tgt))
      end

      def add_legacy_path
        path = root.join("engines", @target, "config/module.rb")
        content = File.read(path)
        old_prefix = "/#{@source}/#{plural}"
        target_suffix = "/#{plural}"

        if content.include?("legacy_paths:")
          unless content.include?(%("#{old_prefix}"))
            content = content.sub(/legacy_paths:\s*\{/, "legacy_paths: { \"#{old_prefix}\" => \"#{target_suffix}\",")
          end
        else
          insertion = "  legacy_paths: { \"#{old_prefix}\" => \"#{target_suffix}\" },\n"
          if content =~ /^(\s*permission_prefixes:.*\n)/
            content = content.sub(/^(\s*permission_prefixes:.*\n)/, "\\1#{insertion}")
          else
            content = content.sub(/\A/, "#{insertion}")
          end
        end

        if content =~ /permission_prefixes:\s*\[([^\]]*)\]/
          prefixes = $1.scan(/"([^"]+)"/).flatten
          unless prefixes.include?(@source)
            prefixes << @source
            content = content.sub(/permission_prefixes:\s*\[[^\]]*\]/, "permission_prefixes: [ #{prefixes.map { |p| "\"#{p}\"" }.join(", ")} ]")
          end
        end
        File.write(path, content)
      end

      def post_write
        inside(root) do
          %w[bundle\ install script/ci/engine_graph npm\ run\ aliases:generate npm\ run\ permissions:generate npm\ run\ errors:generate npm\ run\ i18n:generate npm\ run\ contracts:generate].each do |cmd|
            raise Thor::Error, "post-write step failed: #{cmd}" unless run(cmd)
          end
        end
      end

      def snapshot
        Dir[root.join("**/*")].select { |p| File.file?(p) }.to_h { |p| [ p, File.binread(p) ] }
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
