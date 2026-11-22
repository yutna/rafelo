# frozen_string_literal: true

require "rails/generators"
require "shellwords"
require "yaml"
require_relative "../base/grant_catalog"

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

        source_routes = root.join("engines", @source, "config/routes.rb")
        raise Thor::Error, "source routes not found" unless File.file?(source_routes)
        unless File.read(source_routes).include?("resources :#{plural}")
          raise Thor::Error, "resource not found in source module: #{plural}"
        end

        target_routes = root.join("engines", @target, "config/routes.rb")
        if File.file?(target_routes) && File.read(target_routes).include?("resources :#{plural}")
          raise Thor::Error, "resource already exists in target module: #{plural}"
        end
        if Dir.exist?(root.join("engines", @target, "app/frontend/pages/#{plural}")) ||
           File.exist?(root.join("engines", @target, "app/controllers/#{app_ns_underscore}/#{@target}/#{plural}_controller.rb"))
          raise Thor::Error, "resource already exists in target module: #{plural}"
        end
      end

      def app_namespace = Rails.application.class.module_parent_name
      def app_ns_underscore = app_namespace.gsub(/([a-z\d])([A-Z])/, '\\1_\\2').downcase

      def plural = @res.pluralize
      def singular = @res.singularize

      def perform_move
        move_frontend_trees
        move_engine_files("app/controllers/#{app_ns_underscore}/#{@source}", "app/controllers/#{app_ns_underscore}/#{@target}")
        move_engine_files("app/policies/#{app_ns_underscore}/#{@source}", "app/policies/#{app_ns_underscore}/#{@target}")
        move_engine_files("app/props/#{app_ns_underscore}/#{@source}", "app/props/#{app_ns_underscore}/#{@target}")
        move_engine_files("app/forms/#{app_ns_underscore}/#{@source}", "app/forms/#{app_ns_underscore}/#{@target}")
        move_engine_files("app/gateways/#{app_ns_underscore}/#{@source}", "app/gateways/#{app_ns_underscore}/#{@target}")
        move_engine_files("app/models/#{app_ns_underscore}/#{@source}", "app/models/#{app_ns_underscore}/#{@target}")
        move_engine_files("app/jobs/#{app_ns_underscore}/#{@source}", "app/jobs/#{app_ns_underscore}/#{@target}")
        move_engine_files("spec", "spec")
        move_engine_files("spec/requests", "spec/requests")
        move_engine_files("e2e", "e2e")
        move_root_e2e
        move_tree("config/contracts/pages/#{plural}", "config/contracts/pages/#{plural}")
        move_tree("config/contracts/pages/#{singular}", "config/contracts/pages/#{singular}")
        move_tree("spec/fixtures/upstream/#{plural}", "spec/fixtures/upstream/#{plural}")
        move_tree("spec/fixtures/upstream/#{singular}", "spec/fixtures/upstream/#{singular}")

        move_page_budgets
        move_copy
        rewrite_target_contents
        move_root_request_specs
        rewrite_routes
        move_permissions
        add_legacy_path
        add_legacy_redirect_spec
        move_table_metadata
      end

      def move_frontend_trees
        %w[pages screens containers components hooks domain forms].each do |kind|
          [ plural, singular ].uniq.each do |name|
            move_tree("app/frontend/#{kind}/#{name}", "app/frontend/#{kind}/#{name}")
          end
        end
      end

      def move_tree(from_rel, to_rel)
        from = root.join("engines", @source, from_rel)
        to = root.join("engines", @target, to_rel)
        return unless File.exist?(from)

        FileUtils.mkdir_p(File.dirname(to))
        FileUtils.mv(from, to)
      end

      def move_engine_files(from_dir_rel, to_dir_rel)
        move_files_between(
          root.join("engines", @source, from_dir_rel),
          root.join("engines", @target, to_dir_rel)
        )
      end

      def move_app_files(from_dir_rel, to_dir_rel)
        move_files_between(root.join(from_dir_rel), root.join(to_dir_rel))
      end

      # A slice file carries the resource's singular or plural name. Moving both
      # patterns catches widgets_gateway.rb (plural) and widget_export_job.rb
      # (singular) without touching the engine's other resources.
      def move_files_between(from_dir, to_dir)
        return [] unless Dir.exist?(from_dir)

        files = [ plural, singular ].uniq.flat_map { |name| Dir[from_dir.join("*#{name}*")] }
          .select { |path| File.file?(path) }.uniq
        return [] if files.empty?

        FileUtils.mkdir_p(to_dir)
        files.each { |path| FileUtils.mv(path, to_dir.join(File.basename(path))) }
        files
      end

      def move_page_budgets
        src_path = root.join("engines", @source, "config/budgets.yml")
        tgt_path = root.join("engines", @target, "config/budgets.yml")
        return unless File.file?(src_path) && File.file?(tgt_path)

        src = YAML.safe_load(File.read(src_path), aliases: false) || {}
        tgt = YAML.safe_load(File.read(tgt_path), aliases: false) || {}
        src_pages = src["pages"] || {}
        tgt_pages = tgt["pages"] || {}
        prefix = "#{@source}/#{plural}/"
        moved = src_pages.keys.select { |key| key.start_with?(prefix) }
        return if moved.empty?

        moved.each { |key| tgt_pages[key.sub(prefix, "#{@target}/#{plural}/")] = src_pages.delete(key) }
        src["pages"] = src_pages
        tgt["pages"] = tgt_pages
        File.write(src_path, YAML.dump(src))
        File.write(tgt_path, YAML.dump(tgt))
      end

      def move_copy
        Dir[root.join("engines", @source, "config/locales/*.yml")].sort.each do |src_path|
          locale = File.basename(src_path, ".yml")
          src = YAML.safe_load(File.read(src_path), aliases: false) || {}
          copy = src.dig(locale, @source, plural)
          next unless copy

          src[locale][@source].delete(plural)
          tgt_path = root.join("engines", @target, "config/locales/#{locale}.yml")
          tgt = File.file?(tgt_path) ? YAML.safe_load(File.read(tgt_path), aliases: false) || {} : { locale => {} }
          tgt[locale] ||= {}
          tgt[locale][@target] ||= {}
          tgt[locale][@target][plural] = copy
          File.write(src_path, YAML.dump(src))
          File.write(tgt_path, YAML.dump(tgt))
        end
      end

      def move_table_metadata
        migrations = [ plural, singular ].uniq.flat_map do |name|
          Dir[root.join("engines", @source, "db/migrate/*#{name}*")]
        end
        return if migrations.empty?

        package_path = root.join("engines", @target, "package.yml")
        return unless File.file?(package_path)

        package = YAML.safe_load(File.read(package_path), aliases: false) || {}
        metadata = package["metadata"] || {}
        return if metadata.key?("legacy_table_prefix")

        metadata["legacy_table_prefix"] = @source
        package["metadata"] = metadata
        File.write(package_path, YAML.dump(package))

        ratchet_path = root.join("engines", @target, "config/ratchets.yml")
        return unless File.file?(ratchet_path)

        ratchets = YAML.safe_load(File.read(ratchet_path), aliases: false) || {}
        ratchets["legacy_table_prefixes"] = ratchets.fetch("legacy_table_prefixes", 0).to_i + 1
        File.write(ratchet_path, YAML.dump(ratchets))
      end

      def rewrite_target_contents
        Dir[root.join("engines", @target, "**/*")].select { |p| File.file?(p) }.each do |path|
          body = File.binread(path)
          next if body.include?("\x00")

          changed = body.dup
          changed = changed.gsub("#{app_namespace}::#{@source.camelize}", "#{app_namespace}::#{@target.camelize}")
          changed = changed.gsub("@#{@source}/", "@#{@target}/")
          changed = changed.gsub("module #{@source.camelize}", "module #{@target.camelize}") # unlikely but safe
          changed = changed.gsub("\"#{@source}/#{plural}\"", "\"#{@target}/#{plural}\"")
          changed = changed.gsub("'#{@source}/#{plural}'", "'#{@target}/#{plural}'")
          changed = changed.gsub("/#{@source}/#{plural}", "/#{@target}/#{plural}")
          changed = changed.gsub(":#{@source},", ":#{@target},")
          File.binwrite(path, changed) if changed != body
        end
      end

      def move_root_request_specs
        move_app_files("spec/requests/#{@source}", "spec/requests/#{@target}").each do |path|
          moved_path = root.join("spec/requests", @target, File.basename(path))
          body = File.read(moved_path)
          body = body.gsub("/en/#{@source}/#{plural}", "/en/#{@target}/#{plural}")
          body = body.gsub("/#{@source}/#{plural}", "/#{@target}/#{plural}")
          body = body.gsub("\"#{@source}/#{plural}", "\"#{@target}/#{plural}")
          File.write(moved_path, body)
        end
      end

      def move_root_e2e
        move_app_files("e2e/#{@source}", "e2e/#{@target}").each do |path|
          moved_path = root.join("e2e", @target, File.basename(path))
          body = File.read(moved_path)
          body = body.gsub("/#{@source}/#{plural}", "/#{@target}/#{plural}")
          body = body.gsub("#{@source}.#{plural}.", "#{@target}.#{plural}.")
          body = body.gsub("@#{@source}/", "@#{@target}/")
          File.write(moved_path, body)
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
        # Keep permission keys stable by preserving the source prefix in the target manifest.
        tgt_source_prefix = tgt[@source] || {}
        if src_prefix.key?(plural)
          tgt_source_prefix[plural] = src_prefix.delete(plural)
        end
        src[@source] = src_prefix
        tgt[@source] = tgt_source_prefix
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

      def add_legacy_redirect_spec
        spec_path = root.join("spec/requests", @target, "#{plural}_legacy_redirect_spec.rb")
        FileUtils.mkdir_p(spec_path.dirname)
        content = <<~RUBY
          # frozen_string_literal: true

          require "rails_helper"

          RSpec.describe "#{@target}/#{plural} legacy redirect", type: :request do
            it "redirects the old URL to the moved resource with a 301" do
              get "/en/#{@source}/#{plural}"
              expect(response).to have_http_status(:moved_permanently)
              expect(response).to redirect_to("/en/#{@target}/#{plural}")
            end
          end
        RUBY
        File.write(spec_path, content) unless spec_path.exist?
      end

      def post_write
        Rafelo::Generators::GrantCatalog.sync(root)
        inside(root) do
          %w[bundle\ install script/ci/engine_graph npm\ run\ aliases:generate npm\ run\ permissions:generate npm\ run\ errors:generate npm\ run\ i18n:generate npm\ run\ contracts:generate].each do |cmd|
            raise Thor::Error, "post-write step failed: #{cmd}" unless run(cmd)
          end
          format_written_files
        end
      end

      def format_written_files
        files = Dir[root.join("engines", @target, "app/frontend/**/*.{ts,tsx,mts,json}")]
          .concat(Dir[root.join("engines", @source, "app/frontend/**/*.{ts,tsx,mts,json}")])
          .select { |p| File.file?(p) }
          .reject { |p| p.end_with?(".generated.ts") || p.end_with?(".generated.tsx") || p.include?("/app/frontend/locales/") }
        files.uniq!
        return if files.empty?

        rel = files.map { |p| Pathname.new(p).relative_path_from(root).to_s }
        quoted = rel.map { |p| Shellwords.escape(p) }.join(" ")
        raise Thor::Error, "post-write step failed: npx prettier --write" unless run("npx prettier --write #{quoted}")
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
