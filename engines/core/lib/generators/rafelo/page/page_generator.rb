# frozen_string_literal: true

require "json"
require "rails/generators"
require "yaml"
require_relative "../base/base_generator"
require_relative "../base/post_write"

module Rafelo
  module Generators
    class PageGenerator < Rails::Generators::Base
      include PostWrite

      argument :module_name_arg, type: :string
      argument :resource, type: :string
      class_option :actions, type: :string, default: "index"
      class_option :upstream, type: :string

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
        write_gateway
        write_props
        write_form if write_actions?
        write_frontend
        write_contracts
        write_copy
        write_permissions
        write_fixtures
        write_tests
        post_write
        say "Created #{@mod}/#{resource_plural} (#{effective_actions.join(", ")}).", :green
      rescue StandardError => e
        restore_snapshot(@snapshot) if defined?(@snapshot) && @snapshot
        raise e if e.is_a?(Thor::Error) && !(defined?(@snapshot) && @snapshot)

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
        if options[:upstream].present? && upstream_names.any? && !upstream_names.include?(options[:upstream].to_s)
          raise Thor::Error, "unknown upstream: #{options[:upstream]} (known: #{upstream_names.join(", ")})"
        end

        checks = [
          [ engine_file("config/routes.rb"), :routes ],
          [ engine_file("app/frontend/pages/#{resource_plural}"), :dir ],
          [ engine_file("app/frontend/screens/#{resource_plural}"), :dir ],
          [ engine_file("app/frontend/containers/#{resource_plural}"), :dir ],
          [ engine_file("app/frontend/components/#{resource_plural}"), :dir ],
          [ engine_file("config/contracts/pages/#{resource_plural}"), :dir ],
          [ engine_file("app/controllers/#{app_ns_underscore}/#{mod}/#{resource_plural}_controller.rb"), :file ],
          [ engine_file("app/policies/#{app_ns_underscore}/#{mod}/#{resource_singular}_policy.rb"), :file ],
          [ engine_file("app/gateways/#{app_ns_underscore}/#{mod}/#{resource_plural}_gateway.rb"), :file ],
          [ engine_file("app/forms/#{app_ns_underscore}/#{mod}/#{resource_singular}_form.rb"), :file ],
          [ engine_file("app/props/#{app_ns_underscore}/#{mod}/#{resource_plural}_index_props.rb"), :file ],
          [ engine_file("app/props/#{app_ns_underscore}/#{mod}/#{resource_plural}_show_props.rb"), :file ],
          [ engine_file("app/props/#{app_ns_underscore}/#{mod}/#{resource_plural}_new_props.rb"), :file ],
          [ engine_file("app/props/#{app_ns_underscore}/#{mod}/#{resource_plural}_edit_props.rb"), :file ],
          [ engine_file("spec/fixtures/upstream/#{resource_plural}"), :dir ],
          [ "spec/requests/#{mod}/#{resource_plural}_spec.rb", :file ]
        ]

        existing = checks.any? do |relative, kind|
          path = root.join(relative)
          case kind
          when :routes then File.file?(path) && read_file(path).include?("resources :#{resource_plural}")
          when :dir then Dir.exist?(path)
          when :file then File.exist?(path)
          end
        end

        raise Thor::Error, "resource already exists: #{resource_plural}" if existing
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

      def permission_update = "#{permission_prefix}:#{resource_plural}:update"

      def root = destination_root_path
      def destination_root_path = Pathname.new(destination_root || Dir.pwd)
      def engine_file(path) = "engines/#{mod}/#{path}"
      def app_namespace = Rails.application.class.module_parent_name
      def app_ns_underscore = app_namespace.gsub(/([a-z\d])([A-Z])/, '\\1_\\2').downcase
      def module_class = "#{app_namespace}::#{mod.camelize}"
      def resource_plural = resource_name.pluralize
      def plural = resource_plural
      def resource_singular = resource_name.singularize
      def controller_class = "#{resource_plural.camelize}Controller"
      def page_key_base = "#{mod}/#{resource_plural}"
      def engine_alias = "@#{mod}"
      def permission_read = "#{permission_prefix}:#{resource_plural}:read"
      def permission_create = "#{permission_prefix}:#{resource_plural}:create"

      # A renamed module keeps the manifest's stable route path and permission
      # prefix (GEN-06); new pages must use those, not the engine name.
      def permission_prefix
        @permission_prefix ||= module_manifest[/permission_prefixes:\s*\[(.*?)\]/m, 1]
          &.scan(/"([^"]+)"|'([^']+)'/)&.flatten&.compact&.first || mod
      end

      def route_segment
        @route_segment ||= module_manifest[/path:\s*["']([^"']+)["']/, 1]&.delete_prefix("/") || mod
      end

      def module_manifest
        path = root.join(engine_file("config/module.rb"))
        File.file?(path) ? File.read(path) : ""
      end

      def create_success_route
        target = effective_actions.include?("index") ? resource_plural : "new_#{resource_singular}"
        "page_context.urls.route(:#{mod}, :#{target})"
      end

      def update_success_route
        target = effective_actions.include?("show") ? resource_singular : "edit_#{resource_singular}"
        "page_context.urls.route(:#{mod}, :#{target}, id: params[:id])"
      end
      def capability_key(permission_key) = permission_key.split(":")[1..].join(".")

      def locales
        Rafelo::Core::Locales.available.map(&:to_s)
      end

      def default_locale
        Rafelo::Core::Locales.default.to_s
      end

      def upstream_names
        Rails.application.config.x.upstreams.keys.map(&:to_s)
      rescue StandardError
        []
      end

      def selected_upstream
        (options[:upstream].presence || upstream_names.first || "api").to_sym
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
              query = Rafelo::Core::ListQuery.from(params, sort: %w[id label], filters: {})
              items = gateway(#{module_class}::#{resource_plural.camelize}Gateway).list(
                page: query.page, per_page: query.per_page
              )
              render_page "#{page_key_base}/index", props: #{module_class}::#{resource_plural.camelize}IndexProps.new(
                context: page_context, items: items, query: query
              )
            end
          RUBY
        end
        if effective_actions.include?("show")
          methods << <<~RUBY
            def show
              authorize :#{resource_singular}, :show?, policy_class: #{module_class}::#{resource_singular.camelize}Policy
              render_page "#{page_key_base}/show", props: #{module_class}::#{resource_plural.camelize}ShowProps.new(context: page_context, id: params[:id].to_s)
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
              back = page_context.urls.route(:#{mod}, :new_#{resource_singular})
              if form.invalid?
                return redirect_after_write(back, errors: form.error_messages)
              end

              Rafelo::Core::IdempotencyClaim.call(
                self,
                token: form.token,
                payload: form.payload,
                back: back,
                session_id: Rafelo::Core::Current.session&.id,
                viewer_id: Rafelo::Core::Current.viewer&.id
              ) do |idempotency_key|
                created = gateway(#{module_class}::#{resource_plural.camelize}Gateway).create(
                  payload: form.payload, idempotency_key: idempotency_key
                )
                request.env["rafelo.audit.upstream_id"] = created.id.to_s if created.respond_to?(:id)
                redirect_after_write(#{create_success_route}, notice: "Created.")
              end
            rescue Rafelo::Core::ValidationFailed => error
              redirect_after_write(back, errors: form.translate(error.field_codes))
            rescue Rafelo::Core::ApplicationError => error
              raise unless error.code == "resource.conflict"

              redirect_after_write(back, errors: { "base" => I18n.t("core.errors.fields.conflict") })
            end
          RUBY
        end
        if effective_actions.include?("edit")
          methods << <<~RUBY
            def edit
              authorize :#{resource_singular}, :edit?, policy_class: #{module_class}::#{resource_singular.camelize}Policy
              render_page "#{page_key_base}/edit", props: #{module_class}::#{resource_plural.camelize}EditProps.new(context: page_context, id: params[:id].to_s)
            end
          RUBY
        end
        if effective_actions.include?("update")
          methods << <<~RUBY
            def update
              authorize :#{resource_singular}, :update?, policy_class: #{module_class}::#{resource_singular.camelize}Policy
              form = #{module_class}::#{resource_singular.camelize}Form.new(params.permit(:name, :token, :version))
              back = page_context.urls.route(:#{mod}, :edit_#{resource_singular}, id: params[:id])
              form.errors.add(:version, :blank) if form.version.blank?
              if form.errors.any? || form.invalid?
                return redirect_after_write(back, errors: form.error_messages)
              end

              Rafelo::Core::IdempotencyClaim.call(
                self,
                token: form.token,
                payload: form.payload.merge(id: params[:id].to_s).except(:version),
                back: back,
                session_id: Rafelo::Core::Current.session&.id,
                viewer_id: Rafelo::Core::Current.viewer&.id
              ) do |idempotency_key|
                updated = gateway(#{module_class}::#{resource_plural.camelize}Gateway).update(
                  id: params[:id].to_s, payload: form.payload.except(:version),
                  idempotency_key: idempotency_key, if_match: form.version
                )
                request.env["rafelo.audit.upstream_id"] = updated.id.to_s if updated.respond_to?(:id)
                redirect_after_write(#{update_success_route}, notice: "Updated.")
              end
            rescue Rafelo::Core::ValidationFailed => error
              redirect_after_write(back, errors: form.translate(error.field_codes))
            rescue Rafelo::Core::ApplicationError => error
              raise unless error.code == "resource.conflict"

              redirect_after_write(back, errors: { "base" => I18n.t("core.errors.fields.conflict") })
            end
          RUBY
        end

        create_managed engine_file("app/controllers/#{app_ns_underscore}/#{mod}/#{resource_plural}_controller.rb"), <<~RUBY
          # frozen_string_literal: true

          module #{module_class}
            class #{controller_class} < Rafelo::Core::BaseController
              layout "application"
              throttle to: 30, within: 1.minute, only: %i[#{(effective_actions & %w[create update]).join(" ")}], name: "#{mod}/write"

          #{methods.map { |m| m.rstrip }.join("\n\n")}
            end
          end
        RUBY
      end

      def write_policy
        create_perms = effective_actions.include?("create")
        update_perms = effective_actions.include?("update")
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

              def edit?
                #{update_perms ? "permissions.allows?(#{module_class}::Permissions::#{resource_plural.upcase}_UPDATE)" : "index?"}
              end

              def update? = edit?
            end
          end
        RUBY
      end

      def write_gateway
        upstream = selected_upstream
        methods = []
        if effective_actions.include?("index")
          methods << <<~RUBY
            def list(page:, per_page:)
              payload = JSON.parse(client.get("#{resource_plural}", params: { page: page, per_page: per_page }).body)
              Array(payload["items"] || payload.dig("data", "items"))
            rescue JSON::ParserError
              raise Rafelo::Core::ApplicationError.new("unexpected", "Upstream returned malformed JSON")
            end
          RUBY
        end
        if effective_actions.include?("create")
          methods << <<~RUBY
            def create(payload:, idempotency_key:)
              client.post("#{resource_plural}", body: payload.to_json,
                          headers: { "Content-Type" => "application/json" },
                          idempotency_key: idempotency_key)
            end
          RUBY
        end
        if effective_actions.include?("update")
          methods << <<~RUBY
            def update(id:, payload:, idempotency_key:, if_match:)
              client.patch("#{resource_plural}/\#{id}", body: payload.to_json,
                           headers: { "Content-Type" => "application/json" },
                           idempotency_key: idempotency_key,
                           if_match: if_match)
            end
          RUBY
        end
        create_managed engine_file("app/gateways/#{app_ns_underscore}/#{mod}/#{resource_plural}_gateway.rb"), <<~RUBY
          # frozen_string_literal: true

          module #{module_class}
            class #{resource_plural.camelize}Gateway < Rafelo::Core::Gateway
              upstream :#{upstream}
              token :viewer

          #{methods.map { |method| method.rstrip }.join("\n\n")}
            end
          end
        RUBY
      end

      def write_props
        if effective_actions.include?("index")
          index_can_hash = if effective_actions.include?("new")
            "can: capabilities(#{module_class}::Permissions::#{resource_plural.upcase}_CREATE)"
          else
            "can: {}"
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
            #{policy_decl}      def initialize(context:, items:, query:)
                  super(context: context)
                  @items = Array(items).map { |row| { "id" => row["id"].to_s, "label" => row["label"].to_s } }
                  @query = query
                end

                def envelope
                  {
                    data: { items: @items, newHref: #{effective_actions.include?("new") ? "context.urls.route(:#{mod}, :new_#{resource_singular})" : "nil"} },
                    meta: {},
                    query: {},
                    pagination: {
                      kind: "offset",
                      page: @query.page,
                      perPage: @query.per_page,
                      total: @items.length,
                      pageCount: (@items.length.to_f / @query.per_page).ceil
                    },
                    #{index_can_hash}
                  }
                end
              end
            end
          RUBY
        end

        if effective_actions.include?("show")
          create_managed engine_file("app/props/#{app_ns_underscore}/#{mod}/#{resource_plural}_show_props.rb"), <<~RUBY
            # frozen_string_literal: true

            module #{module_class}
              class #{resource_plural.camelize}ShowProps < Rafelo::Core::PageProps
                def initialize(context:, id:)
                  super(context: context)
                  @id = id
                end

                def envelope
                  {
                    data: {
                      #{resource_singular}: { id: @id, name: @id },
                      indexHref: #{effective_actions.include?("index") ? "context.urls.route(:#{mod}, :#{resource_plural})" : "nil"}
                    },
                    meta: {},
                    query: {},
                    pagination: nil,
                    can: {}
                  }
                end
              end
            end
          RUBY
        end

        if effective_actions.include?("new")
          create_managed engine_file("app/props/#{app_ns_underscore}/#{mod}/#{resource_plural}_new_props.rb"), <<~RUBY
            # frozen_string_literal: true

            module #{module_class}
              class #{resource_plural.camelize}NewProps < Rafelo::Core::PageProps
                def envelope
                  {
                    data: {
                      createHref: context.urls.route(:#{mod}, :#{resource_plural}),
                      indexHref: #{effective_actions.include?("index") ? "context.urls.route(:#{mod}, :#{resource_plural})" : "nil"}
                    },
                    meta: { formToken: Rafelo::Core::FormToken.issue(session_id: context.session_id) },
                    query: {},
                    pagination: nil,
                    can: {}
                  }
                end
              end
            end
          RUBY
        end

        if effective_actions.include?("edit")
          create_managed engine_file("app/props/#{app_ns_underscore}/#{mod}/#{resource_plural}_edit_props.rb"), <<~RUBY
            # frozen_string_literal: true

            module #{module_class}
              class #{resource_plural.camelize}EditProps < Rafelo::Core::PageProps
                def initialize(context:, id:)
                  super(context: context)
                  @id = id
                end

                def envelope
                  {
                    data: {
                      #{resource_singular}: { id: @id, name: @id, version: 1 },
                      updateHref: context.urls.route(:#{mod}, :#{resource_singular}, id: @id),
                      showHref: #{effective_actions.include?("show") ? "context.urls.route(:#{mod}, :#{resource_singular}, id: @id)" : "nil"}
                    },
                    meta: { formToken: Rafelo::Core::FormToken.issue(session_id: context.session_id) },
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
        return unless (effective_actions & %w[create update]).any?

        create_managed engine_file("app/forms/#{app_ns_underscore}/#{mod}/#{resource_singular}_form.rb"), <<~RUBY
          # frozen_string_literal: true

          module #{module_class}
            class #{resource_singular.camelize}Form < Rafelo::Core::Form
              attribute :name, :string
              attribute :version, :string

              validates :name, presence: true
            end
          end
        RUBY
      end

      def write_frontend
        write_i18n_hook
        write_index_frontend if effective_actions.include?("index")
        write_show_frontend if effective_actions.include?("show")
        write_form_component if write_actions?
        write_new_frontend if effective_actions.include?("new")
        write_edit_frontend if effective_actions.include?("edit")
      end

      def write_i18n_hook
        path = root.join(engine_file("app/frontend/i18n.ts"))
        return if File.exist?(path)

        write_managed(path, <<~TS)
          import i18next from "i18next";

          export function #{translation_hook}() {
            return (key: string, options?: Record<string, unknown>): string =>
              i18next.t(key, { ns: "#{mod}", ...options });
          }
        TS
      end

      def translation_hook = "use#{mod.camelize}Translation"

      def import_lines(*lines)
        indent = " " * 10
        types, values = lines.compact.partition { |line| line.start_with?("import type ") }
        external, relative = values.partition do |line|
          !line[/["']([^"']+)["']/, 1].to_s.start_with?(".")
        end
        groups = [ types, external, relative ].reject(&:empty?).map do |group|
          group.sort_by { |line| line[/["']([^"']+)["']/, 1].to_s }.join("\n#{indent}")
        end
        groups.join("\n\n#{indent}")
      end

      def write_index_frontend
        can_keys = effective_actions.include?("new") ? "[\"#{capability_key(permission_create)}\"] as const" : "[] as const"
        data_props = if effective_actions.include?("new")
          "z.object({ items: z.array(z.object({ id: z.string(), label: z.string() })), newHref: hrefSchema.nullable() })"
        else
          "z.object({ items: z.array(z.object({ id: z.string(), label: z.string() })) })"
        end
        index_schema_import = if effective_actions.include?("new")
          "import { hrefSchema } from \"@design_system/safe_url\";\n"
        else
          ""
        end
        create_managed engine_file("app/frontend/pages/#{resource_plural}/index.schema.ts"), <<~TS
          import { definePage } from "@core/contracts/page_props.schema";
          #{index_schema_import}import { z } from "zod";

          export const pageSchema = definePage({
            data: #{data_props},
            query: z.object({}),
            can: #{can_keys},
          });
        TS
        create_managed engine_file("app/frontend/pages/#{resource_plural}/types.ts"), <<~TS
          export type #{resource_singular.camelize}Item = { id: string; label: string };
        TS
        create_managed engine_file("app/frontend/pages/#{resource_plural}/index.tsx"), <<~TSX
          #{import_lines(
            'import type { LayoutName } from "@core/contracts/layout.types";',
            'import { Head } from "@inertiajs/react";',
            "import { #{translation_hook} } from \"#{engine_alias}/i18n\";",
            "import { #{resource_plural.camelize}IndexScreen } from \"#{engine_alias}/screens/#{resource_plural}/index_screen\";",
            'import { pageSchema } from "./index.schema";'
          )}

          export default function #{resource_plural.camelize}Index(props: Record<string, unknown>) {
            const t = #{translation_hook}();
            const page = pageSchema.parse(props);
            return (
              <>
                <Head title={t("#{plural}.title")} />
                <#{resource_plural.camelize}IndexScreen {...page.data} can={page.can} />
              </>
            );
          }

          #{resource_plural.camelize}Index.layoutName = "app" satisfies LayoutName;
        TSX
        create_managed engine_file("app/frontend/screens/#{resource_plural}/index_screen.tsx"), <<~TSX
          import { #{resource_plural.camelize}IndexContainer } from "#{engine_alias}/containers/#{resource_plural}/index_container";

          export function #{resource_plural.camelize}IndexScreen(props: Parameters<typeof #{resource_plural.camelize}IndexContainer>[0]) {
            return <#{resource_plural.camelize}IndexContainer {...props} />;
          }
        TSX
        container_props = if effective_actions.include?("new")
          "  items: { id: string; label: string }[];\n  newHref: Href | null;\n  can: Record<string, { allowed: boolean; reason: string | null }>;"
        else
          "  items: { id: string; label: string }[];\n  can: Record<string, { allowed: boolean; reason: string | null }>;"
        end
        container_args = effective_actions.include?("new") ? "items, newHref, can" : "items, can"
        container_imports = import_lines(
          effective_actions.include?("new") ? 'import { Link, type Href } from "@design_system/public";' : nil,
          "import { #{resource_plural.camelize}List } from \"#{engine_alias}/components/#{resource_plural}/list\";",
          "import { #{translation_hook} } from \"#{engine_alias}/i18n\";"
        )
        new_link = if effective_actions.include?("new")
          <<~TSX.chomp
                    {can["#{capability_key(permission_create)}"]?.allowed && newHref ? (
                      <Link testId="#{mod}.#{resource_plural}.index.new.link" href={newHref}>
                        <span data-testid="#{mod}.#{resource_plural}.index.new">{t("#{plural}.new")}</span>
                      </Link>
                    ) : null}
          TSX
        else
          ""
        end
        create_managed engine_file("app/frontend/containers/#{resource_plural}/index_container.tsx"), <<~TSX
          #{container_imports}

          type Props = {
          #{container_props}
          };

          export function #{resource_plural.camelize}IndexContainer({ #{container_args} }: Props) {
            const t = #{translation_hook}();
            return (
              <section className="mx-auto max-w-3xl px-6 py-16">
                <div className="flex flex-wrap items-end justify-between gap-4">
                  <h1 className="text-display font-semibold" data-testid="#{mod}.#{resource_plural}.index.title">
                    {t("#{plural}.title")}
                  </h1>
          #{new_link}
                </div>
                <#{resource_plural.camelize}List items={items} emptyLabel={t("#{plural}.empty")} />
              </section>
            );
          }
        TSX
        create_managed engine_file("app/frontend/components/#{resource_plural}/list.tsx"), <<~TSX
          import { EmptyState } from "@design_system/public";

          export function #{resource_plural.camelize}List({
            items,
            emptyLabel,
          }: {
            items: { id: string; label: string }[];
            emptyLabel: string;
          }) {
            if (items.length === 0) {
              return <EmptyState testId="#{mod}.#{resource_plural}.index.empty" title={emptyLabel} />;
            }
            return (
              <ul className="mt-4 space-y-2" data-testid="#{mod}.#{resource_plural}.index.list">
                {items.map((item) => (
                  <li key={item.id} data-testid={`#{mod}.#{resource_plural}.index.row.${item.id}`}>
                    {item.label}
                  </li>
                ))}
              </ul>
            );
          }
        TSX
        create_managed engine_file("app/frontend/components/#{resource_plural}/list.test.tsx"), <<~TSX
          import "@testing-library/jest-dom/vitest";
          import { render, screen } from "@testing-library/react";
          import { describe, expect, it } from "vitest";

          import { #{resource_plural.camelize}List } from "./list";

          describe("#{resource_plural.camelize}List", () => {
            it("renders a row with its test id", () => {
              render(<#{resource_plural.camelize}List items={[{ id: "1", label: "Widget" }]} emptyLabel="No widgets" />);

              expect(screen.getByTestId("#{mod}.#{resource_plural}.index.row.1")).toHaveTextContent("Widget");
            });

            it("renders the empty state with the translated label", () => {
              render(<#{resource_plural.camelize}List items={[]} emptyLabel="No widgets" />);

              expect(screen.getByTestId("#{mod}.#{resource_plural}.index.empty")).toHaveTextContent("No widgets");
            });
          });
        TSX
      end

      def write_show_frontend
        create_managed engine_file("app/frontend/pages/#{resource_plural}/show.schema.ts"), <<~TS
          import { definePage } from "@core/contracts/page_props.schema";
          import { hrefSchema } from "@design_system/safe_url";
          import { z } from "zod";

          export const pageSchema = definePage({
            data: z.object({ #{resource_singular}: z.object({ id: z.string(), name: z.string() }), indexHref: hrefSchema.nullable() }),
            query: z.object({}),
            can: [] as const,
            paginated: false,
          });
        TS
        create_managed engine_file("app/frontend/pages/#{resource_plural}/show.tsx"), <<~TSX
          #{import_lines(
            'import type { LayoutName } from "@core/contracts/layout.types";',
            'import { Head } from "@inertiajs/react";',
            "import { #{translation_hook} } from \"#{engine_alias}/i18n\";",
            "import { #{resource_singular.camelize}ShowScreen } from \"#{engine_alias}/screens/#{resource_plural}/show_screen\";",
            'import { pageSchema } from "./show.schema";'
          )}

          export default function #{resource_singular.camelize}Show(props: Record<string, unknown>) {
            const t = #{translation_hook}();
            const page = pageSchema.parse(props);
            return (
              <>
                <Head title={t("#{plural}.title")} />
                <#{resource_singular.camelize}ShowScreen {...page.data} can={page.can} />
              </>
            );
          }

          #{resource_singular.camelize}Show.layoutName = "app" satisfies LayoutName;
        TSX
        create_managed engine_file("app/frontend/screens/#{resource_plural}/show_screen.tsx"), <<~TSX
          import { #{resource_singular.camelize}ShowContainer } from "#{engine_alias}/containers/#{resource_plural}/show_container";

          export function #{resource_singular.camelize}ShowScreen(props: Parameters<typeof #{resource_singular.camelize}ShowContainer>[0]) {
            return <#{resource_singular.camelize}ShowContainer {...props} />;
          }
        TSX
        create_managed engine_file("app/frontend/containers/#{resource_plural}/show_container.tsx"), <<~TSX
          #{import_lines(
            'import { Link, type Href } from "@design_system/public";',
            "import { #{translation_hook} } from \"#{engine_alias}/i18n\";"
          )}

          type Props = {
            #{resource_singular}: { id: string; name: string };
            indexHref: Href | null;
            can: Record<string, { allowed: boolean; reason: string | null }>;
          };

          export function #{resource_singular.camelize}ShowContainer({ #{resource_singular}, indexHref, can }: Props) {
            const t = #{translation_hook}();
            return (
              <section className="mx-auto max-w-3xl px-6 py-16" data-testid="#{mod}.#{resource_plural}.show.page">
                <h1 className="text-display font-semibold">{t("#{plural}.title")}</h1>
                <dl className="mt-4 space-y-2">
                  <div>
                    <dt className="font-medium">{t("#{plural}.id")}</dt>
                    <dd data-testid="#{mod}.#{resource_plural}.show.id">{#{resource_singular}.id}</dd>
                  </div>
                  <div>
                    <dt className="font-medium">{t("#{plural}.name")}</dt>
                    <dd>{#{resource_singular}.name}</dd>
                  </div>
                </dl>
                {indexHref ? (
                  <p className="mt-6">
                    <Link testId="#{mod}.#{resource_plural}.show.back" href={indexHref}>{t("#{plural}.back")}</Link>
                  </p>
                ) : null}
              </section>
            );
          }
        TSX
      end

      def write_form_component
        create_managed engine_file("app/frontend/components/#{resource_plural}/form.tsx"), <<~TSX
          #{import_lines(
            'import { TextField } from "@design_system/public";',
            "import { #{translation_hook} } from \"#{engine_alias}/i18n\";"
          )}

          type Props = {
            name: string;
            errors: Record<string, string>;
            onNameChange: (value: string) => void;
          };

          export function #{resource_singular.camelize}FormFields({ name, errors, onNameChange }: Props) {
            const t = #{translation_hook}();
            return (
              <TextField
                testId="#{mod}.#{resource_plural}.form.name"
                label={t("#{plural}.name")}
                name="name"
                value={name}
                error={errors.name}
                onChange={onNameChange}
              />
            );
          }
        TSX
        create_managed engine_file("app/frontend/components/#{resource_plural}/form.test.tsx"), <<~TSX
          import "@testing-library/jest-dom/vitest";
          import { render, screen } from "@testing-library/react";
          import { describe, expect, it } from "vitest";

          import { #{resource_singular.camelize}FormFields } from "./form";

          describe("#{resource_singular.camelize}FormFields", () => {
            it("renders the design-system field and its error", () => {
              render(
                <#{resource_singular.camelize}FormFields
                  name="Widget"
                  errors={{ name: "can't be blank" }}
                  onNameChange={() => undefined}
                />,
              );

              expect(screen.getByTestId("#{mod}.#{resource_plural}.form.name")).toHaveValue("Widget");
              expect(screen.getByTestId("#{mod}.#{resource_plural}.form.name.error")).toHaveTextContent(
                "can't be blank",
              );
            });
          });
        TSX
      end

      def write_new_frontend
        create_managed engine_file("app/frontend/pages/#{resource_plural}/new.schema.ts"), <<~TS
          import { definePage } from "@core/contracts/page_props.schema";
          import { hrefSchema } from "@design_system/safe_url";
          import { z } from "zod";

          export const pageSchema = definePage({
            data: z.object({ createHref: hrefSchema, indexHref: hrefSchema.nullable() }),
            meta: z.object({ formToken: z.string() }),
            query: z.object({}),
            can: [] as const,
            paginated: false,
          });
        TS
        create_managed engine_file("app/frontend/pages/#{resource_plural}/new.tsx"), <<~TSX
          #{import_lines(
            'import type { LayoutName } from "@core/contracts/layout.types";',
            'import { Head } from "@inertiajs/react";',
            "import { #{translation_hook} } from \"#{engine_alias}/i18n\";",
            "import { #{resource_plural.camelize}NewScreen } from \"#{engine_alias}/screens/#{resource_plural}/new_screen\";",
            'import { pageSchema } from "./new.schema";'
          )}

          export default function #{resource_plural.camelize}New(props: Record<string, unknown>) {
            const t = #{translation_hook}();
            const page = pageSchema.parse(props);
            return (
              <>
                <Head title={t("#{plural}.new")} />
                <#{resource_plural.camelize}NewScreen {...page.data} meta={page.meta} errors={page.errors} />
              </>
            );
          }

          #{resource_plural.camelize}New.layoutName = "app" satisfies LayoutName;
        TSX
        create_managed engine_file("app/frontend/screens/#{resource_plural}/new_screen.tsx"), <<~TSX
          import { #{resource_plural.camelize}NewContainer } from "#{engine_alias}/containers/#{resource_plural}/new_container";

          export function #{resource_plural.camelize}NewScreen(props: Parameters<typeof #{resource_plural.camelize}NewContainer>[0]) {
            return <#{resource_plural.camelize}NewContainer {...props} />;
          }
        TSX
        create_managed engine_file("app/frontend/containers/#{resource_plural}/new_container.tsx"), <<~TSX
          #{import_lines(
            'import { Button, Link, type Href } from "@design_system/public";',
            "import { #{resource_singular.camelize}FormFields } from \"#{engine_alias}/components/#{resource_plural}/form\";",
            "import { #{translation_hook} } from \"#{engine_alias}/i18n\";",
            'import { useForm } from "@inertiajs/react";'
          )}

          type Props = {
            createHref: Href;
            indexHref: Href | null;
            meta: { formToken: string };
            errors: Record<string, string>;
          };

          export function #{resource_plural.camelize}NewContainer({ createHref, indexHref, meta, errors }: Props) {
            const t = #{translation_hook}();
            const form = useForm({ name: "" });
            const formErrors: Record<string, string> = { ...errors, ...form.errors };

            return (
              <section className="mx-auto max-w-3xl px-6 py-16">
                <h1 className="text-display font-semibold">{t("#{plural}.new")}</h1>
                <form
                  onSubmit={(event) => {
                    event.preventDefault();
                    form.transform((data) => ({ ...data, token: meta.formToken }));
                    form.post(createHref);
                  }}
                  className="mt-6 space-y-4"
                >
                  <#{resource_singular.camelize}FormFields
                    name={form.data.name}
                    errors={formErrors}
                    onNameChange={(value) => form.setData("name", value)}
                  />
                  <div className="flex items-center gap-3">
                    <Button testId="#{mod}.#{resource_plural}.new.submit" type="submit" isPending={form.processing}>
                      {t("#{plural}.create")}
                    </Button>
                    {indexHref ? (
                      <Link testId="#{mod}.#{resource_plural}.new.back" href={indexHref}>{t("#{plural}.back")}</Link>
                    ) : null}
                  </div>
                </form>
              </section>
            );
          }
        TSX
      end

      def write_edit_frontend
        create_managed engine_file("app/frontend/pages/#{resource_plural}/edit.schema.ts"), <<~TS
          import { definePage } from "@core/contracts/page_props.schema";
          import { hrefSchema } from "@design_system/safe_url";
          import { z } from "zod";

          export const pageSchema = definePage({
            data: z.object({
              #{resource_singular}: z.object({ id: z.string(), name: z.string(), version: z.number().int() }),
              updateHref: hrefSchema,
              showHref: hrefSchema.nullable(),
            }),
            meta: z.object({ formToken: z.string() }),
            query: z.object({}),
            can: [] as const,
            paginated: false,
          });
        TS
        create_managed engine_file("app/frontend/pages/#{resource_plural}/edit.tsx"), <<~TSX
          #{import_lines(
            'import type { LayoutName } from "@core/contracts/layout.types";',
            'import { Head } from "@inertiajs/react";',
            "import { #{translation_hook} } from \"#{engine_alias}/i18n\";",
            "import { #{resource_plural.camelize}EditScreen } from \"#{engine_alias}/screens/#{resource_plural}/edit_screen\";",
            'import { pageSchema } from "./edit.schema";'
          )}

          export default function #{resource_singular.camelize}Edit(props: Record<string, unknown>) {
            const t = #{translation_hook}();
            const page = pageSchema.parse(props);
            return (
              <>
                <Head title={t("#{plural}.edit")} />
                <#{resource_plural.camelize}EditScreen {...page.data} meta={page.meta} errors={page.errors} />
              </>
            );
          }

          #{resource_singular.camelize}Edit.layoutName = "app" satisfies LayoutName;
        TSX
        create_managed engine_file("app/frontend/screens/#{resource_plural}/edit_screen.tsx"), <<~TSX
          import { #{resource_plural.camelize}EditContainer } from "#{engine_alias}/containers/#{resource_plural}/edit_container";

          export function #{resource_plural.camelize}EditScreen(props: Parameters<typeof #{resource_plural.camelize}EditContainer>[0]) {
            return <#{resource_plural.camelize}EditContainer {...props} />;
          }
        TSX
        create_managed engine_file("app/frontend/containers/#{resource_plural}/edit_container.tsx"), <<~TSX
          #{import_lines(
            'import { Button, Link, type Href } from "@design_system/public";',
            "import { #{resource_singular.camelize}FormFields } from \"#{engine_alias}/components/#{resource_plural}/form\";",
            "import { #{translation_hook} } from \"#{engine_alias}/i18n\";",
            'import { useForm } from "@inertiajs/react";'
          )}

          type Props = {
            #{resource_singular}: { id: string; name: string; version: number };
            updateHref: Href;
            showHref: Href | null;
            meta: { formToken: string };
            errors: Record<string, string>;
          };

          export function #{resource_plural.camelize}EditContainer({
            #{resource_singular},
            updateHref,
            showHref,
            meta,
            errors,
          }: Props) {
            const t = #{translation_hook}();
            const form = useForm({ name: #{resource_singular}.name ?? "" });
            const formErrors: Record<string, string> = { ...errors, ...form.errors };

            return (
              <section className="mx-auto max-w-3xl px-6 py-16">
                <h1 className="text-display font-semibold">{t("#{plural}.edit")}</h1>
                <form
                  onSubmit={(event) => {
                    event.preventDefault();
                    form.transform((data) => ({
                      ...data,
                      token: meta.formToken,
                      version: #{resource_singular}.version,
                    }));
                    form.patch(updateHref);
                  }}
                  className="mt-6 space-y-4"
                >
                  <#{resource_singular.camelize}FormFields
                    name={form.data.name}
                    errors={formErrors}
                    onNameChange={(value) => form.setData("name", value)}
                  />
                  <div className="flex items-center gap-3">
                    <Button testId="#{mod}.#{resource_plural}.edit.submit" type="submit" isPending={form.processing}>
                      {t("#{plural}.save")}
                    </Button>
                    {showHref ? (
                      <Link testId="#{mod}.#{resource_plural}.edit.back" href={showHref}>{t("#{plural}.back")}</Link>
                    ) : null}
                  </div>
                </form>
              </section>
            );
          }
        TSX
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
          block = [ "    #{resource_plural}:" ]
          copy_entries.each { |key, text| block << "      #{key}: #{localized_copy(locale, text)}" }
          next if content.include?("\n    #{resource_plural}:\n")

          if content.match?(/^\s{2}#{Regexp.escape(mod)}:\s*\{\}\s*$/)
            content = content.sub(/^\s{2}#{Regexp.escape(mod)}:\s*\{\}\s*$/, "  #{mod}:")
          end
          write_managed(path, content + "\n" + block.join("\n") + "\n")
        end
      end

      def copy_entries
        entries = { "title" => resource_plural.humanize }
        entries["new"] = "New #{resource_singular.humanize}" if effective_actions.include?("new")
        entries["edit"] = "Edit #{resource_singular.humanize}" if effective_actions.include?("edit")
        entries["empty"] = "No #{resource_plural.humanize.downcase} yet." if effective_actions.include?("index")
        entries["id"] = "ID" if effective_actions.include?("show")
        entries["name"] = "Name" if effective_actions.include?("show") || write_actions?
        entries["create"] = "Create" if effective_actions.include?("create")
        entries["save"] = "Save" if effective_actions.include?("update")
        entries["back"] = "Back" if (effective_actions & %w[show new edit]).any?
        entries
      end

      def localized_copy(locale, text)
        value = locale == default_locale ? text : "[#{locale}] #{text}"
        value.inspect
      end

      def write_permissions
        path = root.join(engine_file("config/permissions.yml"))
        content = read_file(path)
        data = YAML.safe_load(content, aliases: false) || {}
        prefix = data[permission_prefix] || {}
        actions = [ "read" ]
        actions << "create" if effective_actions.include?("create")
        actions << "update" if effective_actions.include?("update")
        prefix[resource_plural] = actions.uniq
        data[permission_prefix] = prefix
        write_managed(path, YAML.dump(data))
      end

      def write_fixtures
        dir = root.join(engine_file("spec/fixtures/upstream/#{resource_plural}"))
        FileUtils.mkdir_p(dir)
        items = Array.new(Rafelo::Core::ListQuery.max_per_page) do |index|
          { "id" => index.to_s, "label" => "Item #{index}" }
        end
        create_managed engine_file("spec/fixtures/upstream/#{resource_plural}/index.json"),
                       JSON.pretty_generate({ "items" => items }) + "\n"
      end

      def write_tests
        grants = [ permission_read ]
        grants << permission_create if effective_actions.include?("create")
        grants << permission_update if effective_actions.include?("update")
        grants_literal = grants.map { |g| "\"#{g}\"" }.join(", ")
        spec = <<~RUBY
          require "rails_helper"

          RSpec.describe "#{mod}/#{resource_plural}", type: :request do
            let(:locale) { I18n.default_locale }
            let(:upstream_base_url) { Rails.application.config.x.upstreams.fetch(:#{selected_upstream}).base_url }

            def sign_in_with(grants)
              viewer = Struct.new(:id, :name).new(7, "Ada")
              _, token = Rafelo::Core::Session.start(
                viewer: viewer, access_token: "a", refresh_token: "r",
                access_expires_at: 5.minutes.from_now,
                grants: grants
              )
              { "Cookie" => "session_token=\#{token}" }
            end

            def form_token(headers, path)
              get path, headers: headers
              PageMatchers.page_of(response).dig("props", "meta", "formToken")
            end
        RUBY

        if effective_actions.include?("index")
          spec << <<~RUBY

            it "renders the index page contract at the maximum page size" do
              headers = sign_in_with([ #{grants_literal} ])
              items = JSON.parse(
                Rails.root.join("engines/#{mod}/spec/fixtures/upstream/#{resource_plural}/index.json").read
              ).fetch("items")
              stub_request(:get, "\#{upstream_base_url}/#{resource_plural}")
                .with(query: { page: "1", per_page: Rafelo::Core::ListQuery.max_per_page.to_s })
                .to_return(status: 200, body: { items: items }.to_json,
                           headers: { "Content-Type" => "application/json" })

              expect { get "/\#{locale}/#{route_segment}/#{resource_plural}?per_page=\#{Rafelo::Core::ListQuery.max_per_page}", headers: headers }.to within_budgets("#{page_key_base}/index")
              expect(response).to have_http_status(:ok)
              expect(response).to match_page_schema("#{page_key_base}/index")
              expect(response).to be_within_props_budget("#{page_key_base}/index")
              expect(response).to have_resolvable_hrefs("#{page_key_base}/index")
              expect(response).to match_policy_capabilities("#{page_key_base}/index")
            end
          RUBY
        end
        if effective_actions.include?("show")
          spec << <<~RUBY

            it "renders the show page contract" do
              headers = sign_in_with([ #{grants_literal} ])
              expect { get "/\#{locale}/#{route_segment}/#{resource_plural}/1", headers: headers }.to within_budgets("#{page_key_base}/show")
              expect(response).to have_http_status(:ok)
              expect(response).to match_page_schema("#{page_key_base}/show")
              expect(response).to be_within_props_budget("#{page_key_base}/show")
              expect(response).to have_resolvable_hrefs("#{page_key_base}/show")
              expect(response).to match_policy_capabilities("#{page_key_base}/show")
            end
          RUBY
        end
        if effective_actions.include?("new")
          spec << <<~RUBY

            it "renders the new page contract" do
              headers = sign_in_with([ #{grants_literal} ])
              expect { get "/\#{locale}/#{route_segment}/#{resource_plural}/new", headers: headers }.to within_budgets("#{page_key_base}/new")
              expect(response).to have_http_status(:ok)
              expect(response).to match_page_schema("#{page_key_base}/new")
              expect(response).to be_within_props_budget("#{page_key_base}/new")
              expect(response).to have_resolvable_hrefs("#{page_key_base}/new")
              expect(response).to match_policy_capabilities("#{page_key_base}/new")
            end
          RUBY
        end
        if effective_actions.include?("edit")
          spec << <<~RUBY

            it "renders the edit page contract" do
              headers = sign_in_with([ #{grants_literal} ])
              expect { get "/\#{locale}/#{route_segment}/#{resource_plural}/1/edit", headers: headers }.to within_budgets("#{page_key_base}/edit")
              expect(response).to have_http_status(:ok)
              expect(response).to match_page_schema("#{page_key_base}/edit")
              expect(response).to be_within_props_budget("#{page_key_base}/edit")
              expect(response).to have_resolvable_hrefs("#{page_key_base}/edit")
              expect(response).to match_policy_capabilities("#{page_key_base}/edit")
            end
          RUBY
        end
        if effective_actions.include?("create")
          spec << <<~RUBY

            it "creates through the gateway, redirects with 303, and replays without a second call" do
              headers = sign_in_with([ #{grants_literal} ])
              token = form_token(headers, "/\#{locale}/#{route_segment}/#{resource_plural}/new")
              stub_request(:post, "\#{upstream_base_url}/#{resource_plural}")
                .to_return(status: 201, body: "{}", headers: { "Content-Type" => "application/json" })

              post "/\#{locale}/#{route_segment}/#{resource_plural}", params: { name: "Widget", token: token }, headers: headers
              expect(response).to have_http_status(:see_other)
              expect(response).to redirect_to("/\#{locale}/#{route_segment}/#{resource_plural}#{effective_actions.include?("index") ? "" : "/new"}")

              post "/\#{locale}/#{route_segment}/#{resource_plural}", params: { name: "Widget", token: token }, headers: headers
              expect(response).to have_http_status(:see_other)
              expect(a_request(:post, "\#{upstream_base_url}/#{resource_plural}")).to have_been_made.once
            end

            it "redirects back with errors when create params are invalid" do
              headers = sign_in_with([ #{grants_literal} ])
              post "/\#{locale}/#{route_segment}/#{resource_plural}", params: { name: "", token: "bad-token" }, headers: headers
              expect(response).to have_http_status(:see_other)
              expect(response).to redirect_to("/\#{locale}/#{route_segment}/#{resource_plural}/new")
            end

            it "redirects back with translated errors when the upstream rejects the create" do
              headers = sign_in_with([ #{grants_literal} ])
              token = form_token(headers, "/\#{locale}/#{route_segment}/#{resource_plural}/new")
              stub_request(:post, "\#{upstream_base_url}/#{resource_plural}")
                .to_return(status: 422, body: '{"errors":{"name":["taken"]}}',
                           headers: { "Content-Type" => "application/json" })

              post "/\#{locale}/#{route_segment}/#{resource_plural}", params: { name: "Widget", token: token }, headers: headers
              expect(response).to have_http_status(:see_other)
              expect(response).to redirect_to("/\#{locale}/#{route_segment}/#{resource_plural}/new")
            end

            it "redirects back with a conflict when the upstream answers 409" do
              headers = sign_in_with([ #{grants_literal} ])
              token = form_token(headers, "/\#{locale}/#{route_segment}/#{resource_plural}/new")
              stub_request(:post, "\#{upstream_base_url}/#{resource_plural}")
                .to_return(status: 409, body: "{}", headers: { "Content-Type" => "application/json" })

              post "/\#{locale}/#{route_segment}/#{resource_plural}", params: { name: "Widget", token: token }, headers: headers
              expect(response).to have_http_status(:see_other)
              expect(response).to redirect_to("/\#{locale}/#{route_segment}/#{resource_plural}/new")
            end
          RUBY
        end
        if effective_actions.include?("update")
          spec << <<~RUBY

            it "updates through the gateway and redirects with 303" do
              headers = sign_in_with([ #{grants_literal} ])
              token = form_token(headers, "/\#{locale}/#{route_segment}/#{resource_plural}/1/edit")
              stub_request(:patch, "\#{upstream_base_url}/#{resource_plural}/1")
                .to_return(status: 200, body: "{}", headers: { "Content-Type" => "application/json" })

              patch "/\#{locale}/#{route_segment}/#{resource_plural}/1", params: { name: "Widget", token: token, version: 1 }, headers: headers
              expect(response).to have_http_status(:see_other)
              expect(response).to redirect_to("/\#{locale}/#{route_segment}/#{resource_plural}/1#{effective_actions.include?("show") ? "" : "/edit"}")
            end

            it "redirects back with errors when update params are invalid" do
              headers = sign_in_with([ #{grants_literal} ])
              patch "/\#{locale}/#{route_segment}/#{resource_plural}/1", params: { name: "", token: "bad-token", version: 1 }, headers: headers
              expect(response).to have_http_status(:see_other)
              expect(response).to redirect_to("/\#{locale}/#{route_segment}/#{resource_plural}/1/edit")
            end

            it "redirects back when the edit version is missing" do
              headers = sign_in_with([ #{grants_literal} ])
              token = form_token(headers, "/\#{locale}/#{route_segment}/#{resource_plural}/1/edit")
              patch "/\#{locale}/#{route_segment}/#{resource_plural}/1", params: { name: "Widget", token: token }, headers: headers
              expect(response).to have_http_status(:see_other)
              expect(response).to redirect_to("/\#{locale}/#{route_segment}/#{resource_plural}/1/edit")
            end

            it "redirects back with a conflict when the upstream rejects the update" do
              headers = sign_in_with([ #{grants_literal} ])
              token = form_token(headers, "/\#{locale}/#{route_segment}/#{resource_plural}/1/edit")
              stub_request(:patch, "\#{upstream_base_url}/#{resource_plural}/1")
                .to_return(status: 409, body: "{}", headers: { "Content-Type" => "application/json" })

              patch "/\#{locale}/#{route_segment}/#{resource_plural}/1", params: { name: "Widget", token: token, version: 1 }, headers: headers
              expect(response).to have_http_status(:see_other)
              expect(response).to redirect_to("/\#{locale}/#{route_segment}/#{resource_plural}/1/edit")
            end
          RUBY
        end
        spec << "  end\n"
        create_managed engine_file("spec/requests/#{resource_plural}_spec.rb"), spec
      end

      def post_write
        Rafelo::Generators::GrantCatalog.sync(root)
        run_post_write(root: root, formatter_files: @written)
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
        File.read(path.to_s)
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
