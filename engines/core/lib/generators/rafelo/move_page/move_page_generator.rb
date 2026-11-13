# frozen_string_literal: true

module Rafelo
  module Generators
    class MovePageGenerator < Rails::Generators::Base
      argument :source_module, type: :string
      argument :target_module, type: :string
      argument :resource, type: :string
      class_option :skip_post_write, type: :boolean, default: false

      def move
        source = source_module.to_s.underscore
        target = target_module.to_s.underscore
        resource = resource.to_s.underscore
        raise Thor::Error, "source engine not found" unless Dir.exist?(Rails.root.join("engines", source))
        raise Thor::Error, "target engine not found" unless Dir.exist?(Rails.root.join("engines", target))

        moves = [
          [ "app/frontend/pages/#{resource}", "app/frontend/pages/#{resource}" ],
          [ "app/frontend/screens/#{resource}", "app/frontend/screens/#{resource}" ],
          [ "app/controllers/rafelo/#{source}/#{resource.pluralize}_controller.rb", "app/controllers/rafelo/#{target}/#{resource.pluralize}_controller.rb" ],
          [ "app/policies/rafelo/#{source}/#{resource}_policy.rb", "app/policies/rafelo/#{target}/#{resource}_policy.rb" ],
          [ "app/props/rafelo/#{source}/#{resource.pluralize}_index_props.rb", "app/props/rafelo/#{target}/#{resource.pluralize}_index_props.rb" ],
          [ "config/contracts/pages/#{resource}", "config/contracts/pages/#{resource}" ]
        ]
        moves.each do |from, to|
          source_path = Rails.root.join("engines", source, from)
          target_path = Rails.root.join("engines", target, to)
          next unless File.exist?(source_path)
          FileUtils.mkdir_p(File.dirname(target_path))
          FileUtils.mv(source_path, target_path)
        end

        Dir[Rails.root.join("engines/#{target}/**/*")].select { |path| File.file?(path) }.each do |path|
          body = File.read(path)
          body = body.gsub("Rafelo::#{source.camelize}", "Rafelo::#{target.camelize}")
          body = body.gsub("#{source}/#{resource}", "#{target}/#{resource}")
          File.write(path, body)
        end
        Dir[Rails.root.join("spec/requests/#{source}/**/*")].select { |path| File.file?(path) && path.include?(resource) }.each do |path|
          body = File.read(path).gsub("\"/en/#{source}/", "\"/en/#{target}/").gsub("#{source}/#{resource}", "#{target}/#{resource}")
          File.write(path, body)
        end

        rewrite_routes(source, target, resource)
        post_write unless options[:skip_post_write]
        say "Moved #{source}/#{resource} to #{target}/#{resource}.", :green
      end

      private

      def rewrite_routes(source, target, resource)
        old_path = Rails.root.join("engines", source, "config/routes.rb")
        old = File.read(old_path)
        old = old.gsub(/^\s*resources :#{resource.pluralize}.*\n/, "")
        unless old.include?("redirect")
          redirect_line = '    get "%s(/*rest)", to: redirect("/en/%s/%s")' % [ resource.pluralize, target, resource.pluralize ]
          old = old.sub("Engine.routes.draw do\n", "Engine.routes.draw do\n#{redirect_line}\n")
        end
        File.write(old_path, old)

        new_path = Rails.root.join("engines", target, "config/routes.rb")
        new = File.read(new_path)
        unless new.include?("resources :#{resource.pluralize}")
          new = new.sub("Engine.routes.draw do\n", "Engine.routes.draw do\n    resources :#{resource.pluralize}, only: %i[index]\n    root to: \"#{resource.pluralize}#index\"\n")
        end
        File.write(new_path, new)
      end

      def post_write
        inside(Rails.root) do
          %w[bundle\ install script/ci/engine_graph].each { |cmd| run(cmd) }
          %w[aliases:generate i18n:generate contracts:generate].each { |cmd| run("npm run #{cmd}") }
        end
      end
    end
  end
end
