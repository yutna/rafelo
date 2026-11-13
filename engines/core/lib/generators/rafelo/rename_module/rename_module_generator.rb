# frozen_string_literal: true

module Rafelo
  module Generators
    class RenameModuleGenerator < Rails::Generators::Base
      argument :old_name, type: :string
      argument :target_name, type: :string
      class_option :skip_post_write, type: :boolean, default: false

      def rename
        source_name = old_name.to_s.underscore
        destination_name = target_name.to_s.underscore
        raise Thor::Error, "engine not found: #{source_name}" unless Dir.exist?(Rails.root.join("engines", source_name))
        raise Thor::Error, "engine already exists: #{destination_name}" if Dir.exist?(Rails.root.join("engines", destination_name))
        raise Thor::Error, "reserved name: #{destination_name}" if %w[core design_system app engines].include?(destination_name) || destination_name.match?(/\A[a-z]{2}\z/)

        old_camel = source_name.camelize
        new_camel = destination_name.camelize
        source = Rails.root.join("engines", source_name)
        target = Rails.root.join("engines", destination_name)

        FileUtils.mv(source, target)
        FileUtils.mv(target.join("rafelo_#{source_name}.gemspec"), target.join("rafelo_#{destination_name}.gemspec"))
        nested = [ "lib/rafelo", "app/controllers/rafelo", "app/policies/rafelo", "app/props/rafelo" ]
        nested.each do |base|
          from = target.join(base, source_name)
          to = target.join(base, destination_name)
          FileUtils.mv(from, to) if Dir.exist?(from)
        end
        old_lib = target.join("lib/rafelo_#{source_name}.rb")
        FileUtils.mv(old_lib, target.join("lib/rafelo_#{destination_name}.rb")) if File.exist?(old_lib)
        Dir[target.join("**/*")].select { |path| File.file?(path) }.each do |path|
          body = File.read(path)
          body = body.gsub("Rafelo::#{old_camel}", "Rafelo::#{new_camel}")
          body = body.gsub(/\b#{old_camel}\b/, new_camel)
          body = body.gsub("rafelo_#{source_name}", "rafelo_#{destination_name}")
          body = body.gsub("@#{source_name}", "@#{destination_name}")
          body = body.gsub("key: :#{source_name}", "key: :#{destination_name}")
          body = body.gsub("path: \"/#{source_name}\"", "path: \"/#{destination_name}\"")
          body = body.gsub("permission_prefixes: [ \"#{source_name}\" ]", "permission_prefixes: [ \"#{destination_name}\" ]")
          body = body.gsub(/^(\s*)#{source_name}:/, "\\1#{destination_name}:")
          body = body.gsub("#{source_name}.nav", "#{destination_name}.nav")
          body = body.gsub("rafelo/#{source_name}", "rafelo/#{destination_name}")
          body = body.gsub("Rafelo #{source_name}", "Rafelo #{destination_name}")
          File.write(path, body)
        end

        unless options[:skip_post_write]
          inside(Rails.root) do
            run "bundle install"
            run "script/ci/engine_graph"
            run "npm run aliases:generate"
            run "npm run i18n:generate"
            run "npm run contracts:generate"
          end
        end
        say "Renamed #{source_name} to #{destination_name}.", :green
      end
    end
  end
end
