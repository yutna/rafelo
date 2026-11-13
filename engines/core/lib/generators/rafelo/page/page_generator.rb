# frozen_string_literal: true

require "shellwords"
require "yaml"
require_relative "../base/base_generator"

module Rafelo
  module Generators
    class PageGenerator < Rails::Generators::Base
      argument :module_name_arg, type: :string
      argument :resource, type: :string
      class_option :actions, type: :string, default: "index"
      class_option :skip_post_write, type: :boolean, default: false

      def create_page
        @mod = module_name_arg.to_s.underscore
        @resource_name = resource.to_s.underscore
        @requested_actions = options[:actions].split(",").map(&:strip).reject(&:empty?)
        validate!
        @snapshot = snapshot
        @written = []

        write_routes
        write_controller
        write_policy
        write_props
        write_form if write_actions?
        write_frontend
        write_contracts
        write_copy
        write_permissions
        write_tests
        post_write unless options[:skip_post_write]
        say "Created #{@mod}/#{resource_plural} (#{effective_actions.join(", ")}).", :green
      rescue StandardError => e
        restore_snapshot(@snapshot) if defined?(@snapshot)
        raise Thor::Error, "generator rolled back after: #{e.message}"
      end

      private

      attr_reader :mod, :resource_name, :requested_actions

      def validate!
        unless requested_actions.all? { |a| %w[index show new edit create update].include?(a) }
          raise Thor::Error, "unknown actions: #{requested_actions.inspect}"
        end
        if resource_name.singularize == resource_name.pluralize
          raise Thor::Error, "resource singular equals plural"
        end
        unless Dir.exist?(root.join("engines", mod))
          raise Thor::Error, "module engine not found: #{mod}"
        end
        routes = read_file(root.join(engine_file("config/routes.rb")))
        if routes.include?("resources :#{resource_plural}")
          raise Thor::Error, "resource already exists: #{resource_plural}"
        end
      end

      def effective_actions
        actions = requested_actions.dup
        actions |= %w[new create] if actions.include?("new") && !actions.include?("create")
        actions |= %w[edit update] if actions.include?("edit") && !actions.include?("update")
        actions = %w[index] if actions.empty?
        actions.uniq
      end

      def write_actions?
        (effective_actions & %w[new create edit update]).any?
      end

      def root = destination_root_path
      def destination_root_path = Pathname.new(destination_root || Dir.pwd)
      def engine_file(path) = "engines/#{mod}/#{path}"
      def app_namespace = Rails.application.class.module_parent_name
      def app_ns_underscore = app_namespace.gsub(/([a-z\d])([A-Z])/, '\\1_\\2').downcase
      def module_class = "#{app_namespace}::#{mod.camelize}"
      def resource_plural = resource_name.pluralize
      def resource_singular = resource_name.singularize
      def controller_class = "#{resource_plural.camelize}Controller"
      def page_key_base = "#{mod}/#{resource_plural}"
      def permission_read = "#{mod}:#{resource_plural}:read"
      def permission_create = "#{mod}:#{resource_plural}:create"

      def locales
        Rafelo::Core::Locales.available.map(&:to_s)
      end

      def default_locale
        Rafelo::Core::Locales.default.to_s
      end

      def write_routes
        path = root.join(engine_file("config/routes.rb"))
        content = read_file(path)
        actions = (effective_actions & %w[index show new edit create update])
        only = actions.map { |a| ":#{a}" }.join(" ")
        line = "    resources :#{resource_plural}, only: %i[#{actions.join(" ")}]\n"
        unless content.include?("resources :#{resource_plural}")
          prefix = ""
          unless content.include?("root to:")
            prefix = "    root to: \"#{resource_plural}#index\"\n" if actions.include?("index")
          end
          content = content.sub("Engine.routes.draw do\n", "Engine.routes.draw do\n#{line}#{prefix}")
          write_managed(path, content)
        end
      end

      def write_controller
        methods = []
        if effective_actions.include?("index")
          methods << <<~RUBY
            def index
              authorize :#{resource_singular}, :index?, policy_class: #{module_class}::#{resource_singular.camelize}Policy
              render_page "#{page_key_base}/index", props: #{module_class}::#{resource_plural.camelize}IndexProps.new(context: page_context)
            end
          RUBY
        end
        if effective_actions.include?("new")
          methods << <<~RUBY
            def new
              authorize :#{resource_singular}, :new?, policy_class: #{module_class}::#{resource_singular.camelize}Policy
              render_page "#{page_key_base}/new", props: #{module_class}::#{resource_plural.camelize}NewProps.new(context: page_context)
            end
          RUBY
        end
        if effective_actions.include?("create")
          methods << <<~RUBY
            def create
              authorize :#{resource_singular}, :create?, policy_class: #{module_class}::#{resource_singular.camelize}Policy
              form = #{module_class}::#{resource_singular.camelize}Form.new(params.permit(:name, :token))
              if form.invalid?
                return redirect_after_write(page_context.urls.route(:#{mod}, :new_#{resource_singular}), errors: form.error_messages)
              end

              Rafelo::Core::IdempotencyClaim.call(
                self,
                token: form.token,
                payload: form.payload,
                back: page_context.urls.route(:#{mod}, :new_#{resource_singular})
              ) do
                redirect_after_write(page_context.urls.route(:#{mod}, :#{resource_plural}), notice: "Created.")
              end
            end
          RUBY
        end

        create_managed engine_file("app/controllers/#{app_ns_underscore}/#{mod}/#{resource_plural}_controller.rb"), <<~RUBY
          # frozen_string_literal: true

          module #{module_class}
            class #{controller_class} < Rafelo::Core::BaseController
              layout "application"

          #{methods.map { |m| m.rstrip }.join("\n\n")}
            end
          end
        RUBY
      end

      def write_policy
        create_perms = effective_actions.include?("create")
        create_managed engine_file("app/policies/#{app_ns_underscore}/#{mod}/#{resource_singular}_policy.rb"), <<~RUBY
          # frozen_string_literal: true

          module #{module_class}
            class #{resource_singular.camelize}Policy < Rafelo::Core::BasePolicy
              def index?
                permissions.allows?(#{module_class}::Permissions::#{resource_plural.upcase}_READ)
              end

              def show? = index?

              def new?
                #{create_perms ? "permissions.allows?(#{module_class}::Permissions::#{resource_plural.upcase}_CREATE)" : "index?"}
              end

              def create? = new?
              def edit? = index?
              def update? = index?
            end
          end
        RUBY
      end

      def write_props
        index_can = []
        index_can_lines = ""
        if effective_actions.include?("new")
          index_can = ["new"]
          index_can_lines = <<~RUBY.chomp
                capabilities(#{module_class}::Permissions::#{resource_plural.upcase}_CREATE)
          RUBY
          index_can_hash = "can: capabilities(#{module_class}::Permissions::#{resource_plural.upcase}_CREATE)"
        else
          index_can_hash = "can: {}"
        end

        policy_decl = if effective_actions.include?("new")
          "      policy_class #{module_class}::#{resource_singular.camelize}Policy\n" \
          "      capability #{module_class}::Permissions::#{resource_plural.upcase}_CREATE, :create?\n\n"
        else
          ""
        end

        create_managed engine_file("app/props/#{app_ns_underscore}/#{mod}/#{resource_plural}_index_props.rb"), <<~RUBY
          # frozen_string_literal: true

          module #{module_class}
            class #{resource_plural.camelize}IndexProps < Rafelo::Core::PageProps
          #{policy_decl}      def envelope
                {
                  data: { items: [], newHref: #{effective_actions.include?("new") ? "context.urls.route(:#{mod}, :new_#{resource_singular})" : "nil"} },
                  meta: {},
                  query: {},
                  pagination: nil,
                  #{index_can_hash}
                }
              end
            end
          end
        RUBY

        if effective_actions.include?("new")
          create_managed engine_file("app/props/#{app_ns_underscore}/#{mod}/#{resource_plural}_new_props.rb"), <<~RUBY
            # frozen_string_literal: true

            module #{module_class}
              class #{resource_plural.camelize}NewProps < Rafelo::Core::PageProps
                def envelope
                  {
                    data: {
                      createPath: context.urls.route(:#{mod}, :#{resource_plural}),
                      indexPath: context.urls.route(:#{mod}, :#{resource_plural})
                    },
                    meta: { formToken: Rafelo::Core::FormToken.issue(session_id: Rafelo::Core::Current.session&.id) },
                    query: {},
                    pagination: nil,
                    can: {}
                  }
                end
              end
            end
          RUBY
        end
      end

      def write_form
        return unless effective_actions.include?("create")

        create_managed engine_file("app/forms/#{app_ns_underscore}/#{mod}/#{resource_singular}_form.rb"), <<~RUBY
          # frozen_string_literal: true

          module #{module_class}
            class #{resource_singular.camelize}Form
              include ActiveModel::Model
              include ActiveModel::Attributes

              attribute :name, :string
              attribute :token, :string

              validates :name, presence: true
              validates :token, presence: true

              def payload
                { name: name.to_s }
              end

              def error_messages
                errors.to_hash(true).transform_values { |messages| Array(messages).first.to_s }
              end
            end
          end
        RUBY
      end

      def write_frontend
        # index
        can_keys = effective_actions.include?("new") ? "[\"#{permission_create}\"] as const" : "[] as const"
        data_props = if effective_actions.include?("new")
          "z.object({ items: z.array(z.object({ id: z.string(), label: z.string() })), newHref: z.string().nullable() })"
        else
          "z.object({ items: z.array(z.object({ id: z.string(), label: z.string() })) })"
        end
        create_managed engine_file("app/frontend/pages/#{resource_plural}/index.schema.ts"), <<~TS
          import { z } from "zod";
          import { definePage } from "@core/contracts/page_props.schema";

          export const pageSchema = definePage({
            data: #{data_props},
            query: z.object({}),
            can: #{can_keys},
            paginated: false,
          });
        TS
        create_managed engine_file("app/frontend/pages/#{resource_plural}/index.tsx"), <<~TSX
          import { Head } from "@inertiajs/react";
          import type { LayoutName } from "@core/contracts/layout.types";
          import { pageSchema } from "./index.schema";
          import { #{resource_plural.camelize}Screen } from "../../screens/#{resource_plural}/index_screen";

          export default function #{resource_plural.camelize}Index(props: Record<string, unknown>) {
            const page = pageSchema.parse(props);
            return (
              <>
                <Head title="#{resource_plural.humanize}" />
                <#{resource_plural.camelize}Screen {...page.data} can={page.can} />
              </>
            );
          }

          #{resource_plural.camelize}Index.layoutName = "app" satisfies LayoutName;
        TSX
        screen_props = effective_actions.include?("new") ? "{ items, newHref, can }: { items: { id: string; label: string }[]; newHref: string | null; can: Record<string, { allowed: boolean; reason: string | null }> }" : "{ items }: { items: { id: string; label: string }[] }"
        new_link = effective_actions.include?("new") ? "\n        {can[\"#{permission_create}\"]?.allowed && newHref ? <a href={newHref}>New</a> : null}" : ""
        create_managed engine_file("app/frontend/screens/#{resource_plural}/index_screen.tsx"), <<~TSX
          export function #{resource_plural.camelize}Screen(#{screen_props}) {
            return (
              <section className="mx-auto max-w-3xl px-6 py-16">
                <h1 className="text-display font-semibold">#{resource_plural.humanize}</h1>#{new_link}
                {items.length === 0 ? <p className="mt-4">No #{resource_plural.humanize.downcase} yet.</p> : null}
              </section>
            );
          }
        TSX

        if effective_actions.include?("new")
          create_managed engine_file("app/frontend/pages/#{resource_plural}/new.schema.ts"), <<~TS
            import { z } from "zod";
            import { definePage } from "@core/contracts/page_props.schema";

            export const pageSchema = definePage({
              data: z.object({ createPath: z.string(), indexPath: z.string() }),
              meta: z.object({ formToken: z.string() }),
              query: z.object({}),
              can: [] as const,
              paginated: false,
            });
          TS
          create_managed engine_file("app/frontend/pages/#{resource_plural}/new.tsx"), <<~TSX
            import { Head } from "@inertiajs/react";
            import type { LayoutName } from "@core/contracts/layout.types";
            import { pageSchema } from "./new.schema";
            import { #{resource_plural.camelize}NewScreen } from "../../screens/#{resource_plural}/new_screen";

            export default function #{resource_plural.camelize}New(props: Record<string, unknown>) {
              const page = pageSchema.parse(props);
              return (
                <>
                  <Head title="New #{resource_singular.humanize}" />
                  <#{resource_plural.camelize}NewScreen {...page.data} meta={page.meta} errors={page.errors} />
                </>
              );
            }

            #{resource_plural.camelize}New.layoutName = "app" satisfies LayoutName;
          TSX
          create_managed engine_file("app/frontend/screens/#{resource_plural}/new_screen.tsx"), <<~TSX
            import { useForm } from "@inertiajs/react";
            import { Button, Link, TextField } from "@design_system/public";

            export function #{resource_plural.camelize}NewScreen({ createPath, indexPath, meta, errors }: { createPath: string; indexPath: string; meta: { formToken: string }; errors: Record<string, string> }) {
              const form = useForm({ name: "", token: meta.formToken });
              return (
                <section className="mx-auto max-w-3xl px-6 py-16">
                  <h1 className="text-display font-semibold">New #{resource_singular.humanize}</h1>
                  <form
                    onSubmit={(event) => {
                      event.preventDefault();
                      form.transform((data) => ({ ...data, token: meta.formToken })).post(createPath);
                    }}
                    className="mt-6 space-y-4"
                  >
                    <TextField
                      testId="#{mod}.#{resource_plural}.new.name"
                      label="Name"
                      name="name"
                      value={form.data.name}
                      onChange={(value) => form.setData("name", value)}
                      error={errors.name}
                    />
                    <div className="flex gap-3">
                      <Button testId="#{mod}.#{resource_plural}.new.submit" type="submit">Create</Button>
                      <Link href={indexPath}>Back</Link>
                    </div>
                  </form>
                </section>
              );
            }
          TSX
        end
      end

      def write_contracts
        # contracts are generated by script, but ensure dirs exist
        FileUtils.mkdir_p(root.join(engine_file("config/contracts/pages/#{resource_plural}")))
      end

      def write_copy
        locales.each do |locale|
          path = root.join(engine_file("config/locales/#{locale}.yml"))
          next unless File.file?(path)
          content = read_file(path).rstrip
          block = ["    #{resource_plural}:", "      title: \"#{resource_plural.humanize}\""]
          block << "      new: \"New #{resource_singular.humanize}\"" if effective_actions.include?("new")
          unless content.include?("\n    #{resource_plural}:\n")
            write_managed(path, content + "\n" + block.join("\n") + "\n")
          end
        end
      end

      def write_permissions
        path = root.join(engine_file("config/permissions.yml"))
        content = read_file(path)
        data = YAML.safe_load(content, aliases: false) || {}
        prefix = data[mod] || {}
        actions = ["read"]
        actions << "create" if effective_actions.include?("create")
        prefix[resource_plural] = actions.uniq
        data[mod] = prefix
        write_managed(path, YAML.dump(data))
      end

      def write_tests
        grants = [permission_read]
        grants << permission_create if effective_actions.include?("create")
        grants_literal = grants.map { |g| "\"#{g}\"" }.join(", ")
        index_spec = <<~RUBY
          require "rails_helper"

          RSpec.describe "#{mod}/#{resource_plural}", type: :request do
            def sign_in_with(grants)
              viewer = Struct.new(:id, :name).new(7, "Ada")
              _, token = Rafelo::Core::Session.start(
                viewer: viewer, access_token: "a", refresh_token: "r",
                access_expires_at: 5.minutes.from_now,
                grants: grants
              )
              { "Cookie" => "session_token=\#{token}" }
            end

            it "renders the index page contract" do
              headers = sign_in_with([#{grants_literal}])
              expect { get "/en/#{mod}/#{resource_plural}", headers: headers }.to within_budgets("#{page_key_base}/index")
              expect(response).to have_http_status(:ok)
              expect(response).to match_page_schema("#{page_key_base}/index")
              expect(response).to be_within_props_budget("#{page_key_base}/index")
              expect(response).to have_resolvable_hrefs("#{page_key_base}/index")
              expect(response).to match_policy_capabilities("#{page_key_base}/index")
            end
        RUBY
        if effective_actions.include?("new")
          index_spec << <<~RUBY

            it "renders the new page contract" do
              headers = sign_in_with([#{grants_literal}])
              expect { get "/en/#{mod}/#{resource_plural}/new", headers: headers }.to within_budgets("#{page_key_base}/new")
              expect(response).to have_http_status(:ok)
              expect(response).to match_page_schema("#{page_key_base}/new")
              expect(response).to be_within_props_budget("#{page_key_base}/new")
              expect(response).to have_resolvable_hrefs("#{page_key_base}/new")
              expect(response).to match_policy_capabilities("#{page_key_base}/new")
            end
          RUBY
        end
        index_spec << "  end\n"
        create_managed "spec/requests/#{mod}/#{resource_plural}_spec.rb", index_spec
      end

      def post_write
        inside(root) do
          run_step "bundle install"
          run_step "script/ci/engine_graph"
          run_step "npm run aliases:generate"
          run_step "npm run permissions:generate"
          run_step "npm run errors:generate"
          run_step "npm run i18n:generate"
          run_step "npm run contracts:generate"
          prettier_targets
        end
      end

      def prettier_targets
        files = @written.select { |p| p.end_with?(".ts", ".tsx", ".mts", ".json") && File.file?(p) }
        return if files.empty?

        rel = files.map { |p| Pathname.new(p).relative_path_from(root).to_s }
        quoted = rel.map { |p| Shellwords.escape(p) }.join(" ")
        run_step "npx prettier --write #{quoted}"
      end

      def run_step(command)
        ok = run(command)
        raise Thor::Error, "post-write step failed: #{command}" unless ok
      end

      def snapshot
        paths = Dir[root.join("**/*")].select { |p| File.file?(p) }
        paths.to_h { |p| [p, File.binread(p)] }
      end

      def restore_snapshot(before)
        after = Dir[root.join("**/*")].select { |p| File.file?(p) }
        (after - before.keys).each { |p| FileUtils.rm_f(p) }
        before.each { |p, content| File.binwrite(p, content) unless File.file?(p) && File.binread(p) == content }
        prune_empty_dirs
      end

      def prune_empty_dirs
        Dir[root.join("**/*")].select { |p| File.directory?(p) }.sort_by(&:length).reverse_each do |dir|
          Dir.rmdir(dir) if (Dir.entries(dir) - %w[. ..]).empty?
        end
      rescue StandardError
        nil
      end

      def read_file(path)
        File.read(path)
      end

      def create_managed(relative, content)
        path = root.join(relative)
        FileUtils.mkdir_p(File.dirname(path))
        File.write(path, content)
        @written << path.to_s
      end

      def write_managed(path, content)
        FileUtils.mkdir_p(File.dirname(path))
        File.write(path, content)
        @written << path.to_s
      end
    end
  end
end
