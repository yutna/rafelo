# frozen_string_literal: true

require_relative "../base/base_generator"

module Rafelo
  module Generators
    class PageGenerator < Rails::Generators::Base
      argument :module_name_arg, type: :string
      argument :resource, type: :string
      class_option :actions, type: :string, default: "index"
      class_option :skip_post_write, type: :boolean, default: false

      def create_page
        @module_name = module_name_arg.to_s.underscore
        @resource = resource.to_s.underscore
        actions = options[:actions].split(",").map(&:strip).reject(&:empty?)
        raise Thor::Error, "unknown actions: #{actions.inspect}" unless actions.all? { |action| %w[index show new edit].include?(action) }
        raise Thor::Error, "resource singular equals plural" if @resource.singularize == @resource.pluralize
        raise Thor::Error, "module engine not found: #{@module_name}" unless Dir.exist?(Rails.root.join("engines", @module_name))
        routes = File.read(Rails.root.join("engines", @module_name, "config/routes.rb"))
        raise Thor::Error, "resource already exists: #{@resource.pluralize}" if routes.include?("resources :#{@resource.pluralize}")

        with_rollback do
          write_routes(actions)
          write_controller(actions)
          write_policy
          write_props
          write_frontend(actions)
          write_copy
          write_permissions
          write_test
          post_write unless options[:skip_post_write]
        end
        say "Created #{@module_name}/#{@resource} (#{actions.join(", ")}).", :green
      end

      private

      def namespace = Rails.application.class.module_parent_name

      def with_rollback
        engine = Rails.root.join("engines", @module_name)
        before = generated_tree_state
        yield
      rescue StandardError => error
        restore_tree(before)
        raise Thor::Error, "generator rolled back after: #{error.message}"
      end

      def generated_tree_state
        files = %w[.dependency-cruiser.engines.generated.json Gemfile.lock tsconfig.json tsconfig.base.json tsconfig.tooling.json app/frontend/tsconfig.json config/frontend_aliases.mts]
        files.to_h { |path| [ path, File.file?(Rails.root.join(path)) ? File.binread(Rails.root.join(path)) : nil ] }
      end

      def restore_tree(before)
        before.each do |path, content|
          target = Rails.root.join(path)
          content.nil? ? FileUtils.rm_f(target) : File.binwrite(target, content)
        end
      end

      def post_write
        inside(Rails.root) do
          run_step "bundle install"
          run_step "script/ci/engine_graph"
          run_step "npm run aliases:generate"
          run_step "npm run i18n:generate"
          run_step "npm run errors:generate"
          run_step "npm run contracts:generate"
        end
      end

      def run_step(command)
        raise Thor::Error, "generator step failed: #{command}" unless run(command)
      end

      def engine_dir = "engines/#{@module_name}"
      def module_class = "#{namespace}::#{@module_name.camelize}"
      def controller_class = "#{@resource.pluralize.camelize}Controller"
      def page_base = "#{@module_name}/#{@resource.pluralize}"

      def write_routes(actions)
        path = Rails.root.join(engine_dir, "config/routes.rb")
        content = File.read(path)
        entry = "    resources :#{@resource.pluralize}, only: %i[#{actions.join(" ")}]\n"
        if content.include?("resources :#{@resource.pluralize}")
          return
        end
        root = content.include?("root to:") ? "" : "    root to: \"#{@resource.pluralize}#index\"\n"
        content = content.sub("Engine.routes.draw do\n", "Engine.routes.draw do\n#{entry}#{root}")
        File.write(path, content)
      end

      def write_controller(actions)
        body = actions.map do |action|
          if action == "index"
            <<~RUBY
              def index
                authorize :#{@resource}, :index?, policy_class: #{module_class}::#{@resource.camelize}Policy
                render_page "#{page_base}/index", props: #{module_class}::#{@resource.pluralize.camelize}IndexProps.new(context: page_context)
              end
            RUBY
          else
            "    # TODO: #{action} follows BE-13/BE-15.\n"
          end
        end.join("\n")
        create_file "#{engine_dir}/app/controllers/rafelo/#{@module_name}/#{@resource.pluralize}_controller.rb", <<~RUBY
          # frozen_string_literal: true

          module #{module_class}
            class #{controller_class} < Rafelo::Core::BaseController
              layout "application"

          #{body.gsub(/^/, "    ")}
            end
          end
        RUBY
      end

      def write_policy
        create_file "#{engine_dir}/app/policies/rafelo/#{@module_name}/#{@resource}_policy.rb", <<~RUBY
          # frozen_string_literal: true

          module #{module_class}
            class #{@resource.camelize}Policy < Rafelo::Core::BasePolicy
              def index? = permissions.allows?(#{module_class}::Permissions::#{@resource.pluralize.upcase}_READ)
              def show? = index?
              def new? = index?
              def create? = index?
              def edit? = index?
              def update? = index?
            end
          end
        RUBY
      end

      def write_props
        create_file "#{engine_dir}/app/props/rafelo/#{@module_name}/#{@resource.pluralize}_index_props.rb", <<~RUBY
          # frozen_string_literal: true

          module #{module_class}
            class #{@resource.pluralize.camelize}IndexProps < Rafelo::Core::PageProps
              def envelope
                { data: { items: [] }, meta: {}, query: {}, pagination: nil, can: {} }
              end
            end
          end
        RUBY
      end

      def write_frontend(actions)
        create_file "#{engine_dir}/app/frontend/pages/#{@resource.pluralize}/index.schema.ts", <<~TS
          import { z } from "zod";
          import { definePage } from "@core/contracts/page_props.schema";

          export const pageSchema = definePage({
            data: z.object({ items: z.array(z.object({ id: z.string(), label: z.string() })) }),
            query: z.object({}),
            can: [] as const,
            paginated: false,
          });
        TS
        create_file "#{engine_dir}/app/frontend/pages/#{@resource.pluralize}/index.tsx", <<~TSX
          import { Head } from "@inertiajs/react";
          import type { LayoutName } from "@core/contracts/layout.types";
          import { pageSchema } from "./index.schema";
          import { #{@resource.pluralize.camelize}Screen } from "../../screens/#{@resource.pluralize}/index_screen";

          export default function #{@resource.pluralize.camelize}Index(props: Record<string, unknown>) {
            const page = pageSchema.parse(props);
            return (
              <>
                <Head title={page.data.items.length ? "#{@resource.pluralize.humanize}" : "#{@resource.pluralize.humanize}"} />
                <#{@resource.pluralize.camelize}Screen items={page.data.items} />
              </>
            );
          }

          #{@resource.pluralize.camelize}Index.layoutName = "app" satisfies LayoutName;
        TSX
        create_file "#{engine_dir}/app/frontend/screens/#{@resource.pluralize}/index_screen.tsx", <<~TSX
          type Props = { items: { id: string; label: string }[] };

          export function #{@resource.pluralize.camelize}Screen({ items }: Props) {
            return (
              <section className="mx-auto max-w-3xl px-6 py-16">
                <h1 className="text-display font-semibold">#{@resource.pluralize.humanize}</h1>
                {items.length === 0 ? <p className="mt-4">No #{@resource.pluralize.humanize.downcase} yet.</p> : null}
              </section>
            );
          }
        TSX
      end

      def write_copy
        Rafelo::Core::Locales.available.map(&:to_s).each do |locale|
          path = Rails.root.join(engine_dir, "config/locales/#{locale}.yml")
          next unless File.file?(path)
          File.write(path, File.read(path).rstrip + "\n    #{@resource.pluralize}:\n      title: \"#{@resource.pluralize.humanize}\"\n")
        end
      end

      def write_permissions
        path = Rails.root.join(engine_dir, "config/permissions.yml")
        File.write(path, File.read(path).rstrip + "\n  #{@resource.pluralize}: [read]\n")
      end

      def write_test
        create_file "spec/requests/#{@module_name}/#{@resource.pluralize}_spec.rb", <<~RUBY
          require "rails_helper"

          RSpec.describe "#{@module_name}/#{@resource.pluralize}", type: :request do
            it "renders the page contract" do
              viewer = Struct.new(:id, :name).new(7, "Ada")
              _, token = Rafelo::Core::Session.start(
                viewer: viewer, access_token: "a", refresh_token: "r",
                access_expires_at: 5.minutes.from_now,
                grants: [ "#{@module_name}:#{@resource.pluralize}:read" ]
              )
              cookie = "session_token=#{token}"
              expect { get "/en/#{@module_name}/#{@resource.pluralize}", headers: { "Cookie" => cookie } }.to within_budgets("#{page_base}/index")
              expect(response).to have_http_status(:ok)
              expect(response).to match_page_schema("#{page_base}/index")
              expect(response).to be_within_props_budget("#{page_base}/index")
              expect(response).to have_resolvable_hrefs("#{page_base}/index")
              expect(response).to match_policy_capabilities("#{page_base}/index")
            end
          end
        RUBY
      end
    end
  end
end
