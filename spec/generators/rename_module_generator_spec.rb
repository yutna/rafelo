require "rails_helper"
require "tmpdir"
require "json"
require "yaml"
require Rails.root.join("engines/core/lib/generators/rafelo/rename_module_generator")

RSpec.describe Rafelo::Generators::RenameModuleGenerator do
  def write_file(root, relative, body)
    path = root.join(relative)
    FileUtils.mkdir_p(path.dirname)
    File.write(path, body)
  end

  it "renames engine and keeps module path/permission prefixes stable" do
    Dir.mktmpdir do |dir|
      root = Pathname(dir)
      src = root.join("engines/billing")
      FileUtils.mkdir_p(src.join("config/initializers"))
      FileUtils.mkdir_p(src.join("lib/rafelo/billing"))
      File.write(src.join("package.yml"), YAML.dump("enforce_dependencies" => "strict", "dependencies" => []))
      File.write(src.join("config/ratchets.yml"), YAML.dump("eslint_disable" => 0))
      File.write(src.join("config/module.rb"), <<~RUBY)
        Rafelo::Core::Modules.register(
          key: :billing,
          engine: Object,
          path: "/billing",
          permission_prefixes: ["billing"],
          nav: { order: 10, label_key: "billing.nav.title", icon: "folder" }
        )
      RUBY
      File.write(src.join("config/permissions.yml"), YAML.dump("billing" => { "widgets" => [ "read" ] }))
      File.write(src.join("lib/rafelo/billing/engine.rb"), "module Rafelo::Billing; class Engine < Rails::Engine; end; end\n")
      dependent = root.join("engines/shipper")
      FileUtils.mkdir_p(dependent)
      File.write(dependent.join("package.yml"), YAML.dump("dependencies" => [ "engines/core", "engines/billing" ]))
      engine_spec = src.join("spec/requests/widgets_spec.rb")
      FileUtils.mkdir_p(engine_spec.dirname)
      File.write(engine_spec, <<~RUBY)
        RSpec.describe "billing/widgets" do
          let(:fixture) { Rails.root.join("engines/billing/spec/fixtures/upstream/widgets/index.json") }
          it { get "/en/billing/widgets"; page_context.urls.route(:billing, :widgets) }
        end
      RUBY

      described_class.start([ "billing", "invoicing", "--skip-post-write" ], destination_root: dir)

      expect(root.join("engines/billing")).not_to exist
      expect(root.join("engines/invoicing")).to exist
      mod_rb = File.read(root.join("engines/invoicing/config/module.rb"))
      expect(mod_rb).to include('path: "/billing"')
      expect(mod_rb).to include('"billing"')
      expect(mod_rb).not_to include('permission_prefixes: ["invoicing"]')

      perms = YAML.safe_load(File.read(root.join("engines/invoicing/config/permissions.yml")))
      expect(perms).to have_key("billing")
      expect(perms).not_to have_key("invoicing")
      expect(perms.dig("billing", "widgets")).to eq([ "read" ])

      pkg = YAML.safe_load(File.read(root.join("engines/invoicing/package.yml")))
      expect(pkg.dig("metadata", "legacy_table_prefix")).to eq("billing")
      expect(root.join("engines/invoicing/config/initializers/legacy_constants.rb")).to exist
      ratchets = YAML.safe_load(File.read(root.join("engines/invoicing/config/ratchets.yml")))
      expect(ratchets["legacy_table_prefixes"]).to eq(1)
      expect(ratchets["legacy_constants"]).to eq(1)

      dependent_package = YAML.safe_load(File.read(dependent.join("package.yml")))
      expect(dependent_package["dependencies"]).to eq([ "engines/core", "engines/invoicing" ])

      spec = File.read(root.join("engines/invoicing/spec/requests/widgets_spec.rb"))
      expect(spec).to include('"invoicing/widgets"')
      expect(spec).to include("engines/invoicing/spec/fixtures/upstream/widgets/index.json")
      expect(spec).to include("route(:invoicing")
      expect(spec).to include('get "/en/billing/widgets"')
    end
  end

  it "renames every reference and leaves only stable URLs, permissions, and legacy entries" do
    Dir.mktmpdir do |dir|
      root = Pathname(dir)
      engine = root.join("engines/billing")
      write_file(root, "engines/billing/rafelo_billing.gemspec", <<~RUBY)
        require_relative "lib/rafelo/billing/version"

        Gem::Specification.new do |spec|
          spec.name = "rafelo_billing"
          spec.summary = "Rafelo billing module"
          spec.description = "The billing product module of the Rafelo BFF template."
        end
      RUBY
      write_file(root, "engines/billing/lib/rafelo_billing.rb", "require \"rafelo/billing/engine\"\n")
      write_file(root, "engines/billing/lib/rafelo/billing/version.rb", "module Rafelo\n  module Billing\n    VERSION = \"0.1.0\"\n  end\nend\n")
      write_file(root, "engines/billing/lib/rafelo/billing/engine.rb", <<~RUBY)
        module Rafelo
          module Billing
            class Engine < Rails::Engine
              isolate_namespace Rafelo::Billing
            end
          end
        end
      RUBY
      write_file(root, "engines/billing/package.yml", YAML.dump("enforce_dependencies" => "strict", "dependencies" => [ "engines/core", "engines/design_system" ]))
      write_file(root, "engines/billing/config/ratchets.yml", YAML.dump("legacy_table_prefixes" => 0, "legacy_constants" => 0))
      write_file(root, "engines/billing/config/module.rb", <<~RUBY)
        Rafelo::Core::Modules.register(
          key: :billing,
          engine: Rafelo::Billing::Engine,
          path: "/billing",
          permission_prefixes: [ "billing", "shared" ],
          nav: { order: 10, label_key: "billing.nav.title", icon: "folder" }
        )
      RUBY
      write_file(root, "engines/billing/config/routes.rb", "Rafelo::Billing::Engine.routes.draw do\n  resources :widgets\nend\n")
      write_file(root, "engines/billing/config/permissions.yml", YAML.dump("billing" => { "widgets" => [ "read" ] }))
      write_file(root, "engines/billing/config/budgets.yml", YAML.dump("pages" => { "billing/widgets/index" => { "sql_queries_per_request" => 2 } }))
      write_file(root, "engines/billing/config/errors.yml", <<~YAML)
        billing.widget_missing:
          status: 404
          i18n_key: billing.errors.widget_missing
          retryable: false
      YAML
      write_file(root, "engines/billing/config/locales/en.yml", YAML.dump("en" => { "billing" => { "nav" => { "title" => "Billing" }, "widgets" => { "title" => "Billing widgets" } } }))
      write_file(root, "engines/billing/app/frontend/public/index.ts", "export const MODULE_NAME = \"billing\";\n")
      write_file(root, "engines/billing/app/frontend/i18n.ts", <<~TS)
        import i18next from "i18next";

        export function useBillingTranslation() {
          return (key: string) => i18next.t(key, { ns: "billing" });
        }
      TS
      write_file(root, "engines/billing/app/frontend/errors.generated.ts", "export const errors = {\n  \"billing.widget_missing\": { status: 404, retryable: false },\n} as const;\n")
      write_file(root, "engines/billing/app/frontend/permissions.generated.ts", "export const Permissions = {\n  WIDGETS_READ: \"billing:widgets:read\",\n} as const;\n")
      write_file(root, "engines/billing/app/frontend/components/widgets/list.tsx", <<~TSX)
        import { useBillingTranslation } from "@billing/i18n";

        export function WidgetsList() {
          const t = useBillingTranslation();
          return <ul data-testid="billing.widgets.index.list">{t("widgets.title")}</ul>;
        }
      TSX
      write_file(root, "engines/billing/app/public/rafelo/billing/permissions.rb", <<~RUBY)
        module Rafelo
          module Billing
            module Permissions
              WIDGETS_READ = "billing:widgets:read"
            end
          end
        end
      RUBY
      write_file(root, "engines/billing/app/controllers/rafelo/billing/widgets_controller.rb", <<~RUBY)
        module Rafelo
          module Billing
            class WidgetsController < Rafelo::Core::BaseController
              throttle to: 30, within: 1.minute, name: "billing/write"

              def index
                render_page "billing/widgets/index", props: {}
              end

              def back = page_context.urls.route(:billing, :widgets)
              def title = t("billing.widgets.title")
            end
          end
        end
      RUBY
      write_file(root, "engines/billing/app/props/rafelo/billing/widgets_index_props.rb", <<~RUBY)
        module Rafelo
          module Billing
            class WidgetsIndexProps < Rafelo::Core::PageProps
              def title = I18n.t("billing.widgets.title")
            end
          end
        end
      RUBY
      write_file(root, "engines/billing/vitest.config.mts", <<~TS)
        export default { test: { projects: [{ test: { name: "billing" } }, { test: { name: "billing:node" } }] } };
      TS
      write_file(root, "engines/billing/tsconfig.json", "{\"compilerOptions\":{\"outDir\":\"../../tmp/tsc/billing\"}}\n")
      write_file(root, "engines/billing/README.md", "# billing\n\nThe billing module.\n")
      write_file(root, "engines/billing/AGENTS.md", "# Rafelo::Billing\n\nThe billing module.\n")
      write_file(root, "engines/billing/e2e/widgets.spec.ts", <<~TS)
        test.describe("billing", () => {
          test("lists", async ({ page }) => {
            await page.goto("/en/billing/widgets");
            await expect(page.getByTestId("billing.widgets.index.list")).toBeVisible();
          });
        });
      TS
      write_file(root, "spec/requests/billing/widgets_spec.rb", <<~RUBY)
        RSpec.describe "billing/widgets" do
          it "renders" do
            get "/en/billing/widgets"
            within_budgets("billing/widgets/index")
            grants = [ "billing:widgets:read" ]
            fixture = Rails.root.join("engines/billing/spec/fixtures/upstream/widgets/index.json")
          end
        end
      RUBY
      write_file(root, "e2e/billing/widgets.spec.ts", <<~TS)
        test.describe("billing", () => {
          test("lists", async ({ page }) => {
            await page.goto("/en/billing/widgets");
            await expect(page.getByTestId("billing.widgets.index.list")).toBeVisible();
          });
        });
      TS
      write_file(root, "engines/shipper/package.yml", YAML.dump("dependencies" => [ "engines/core", "engines/billing" ]))
      write_file(root, "engines/shipper/app/frontend/public/index.ts", <<~TS)
        import { Widget } from "@billing/public";
        export const ShippingWidget = Widget;
      TS
      write_file(root, "engines/shipper/app/models/rafelo/shipper/shipment.rb", "module Rafelo\n  module Shipper\n    Shipment = Rafelo::Billing::Widget\n  end\nend\n")
      write_file(root, "config/frontend_aliases.mts", <<~TS)
        export const engineAliases = [
          { find: "@billing", replacement: `${root}/engines/billing/app/frontend` },
        ];
      TS
      write_file(root, "config/grants.json", JSON.pretty_generate("grants" => [ "billing:widgets:read" ]) + "\n")

      described_class.start([ "billing", "invoicing", "--skip-post-write" ], destination_root: dir)

      target = root.join("engines/invoicing")
      expect(target).to exist
      expect(root.join("engines/billing")).not_to exist
      expect(target.join("rafelo_invoicing.gemspec")).to exist
      expect(File.read(target.join("rafelo_invoicing.gemspec"))).not_to include("billing")
      expect(File.read(target.join("vitest.config.mts"))).to include('name: "invoicing"').and include('name: "invoicing:node"')
      expect(File.read(target.join("app/frontend/public/index.ts"))).to include('MODULE_NAME = "invoicing"')
      expect(File.read(target.join("app/frontend/i18n.ts"))).to include("useInvoicingTranslation").and include('ns: "invoicing"')
      expect(File.read(target.join("app/frontend/components/widgets/list.tsx"))).to include("@invoicing/i18n").and include('data-testid="invoicing.widgets.index.list"')
      budgets = File.read(target.join("config/budgets.yml"))
      expect(budgets).to include("invoicing/widgets/index")
      expect(budgets).not_to include("billing/widgets")
      expect(File.read(target.join("config/errors.yml"))).to include("invoicing.widget_missing").and include("invoicing.errors.widget_missing")
      expect(File.read(target.join("config/locales/en.yml"))).to include("invoicing:").and include('title: Invoicing')
      expect(File.read(target.join("config/module.rb"))).to include("key: :invoicing").and include('label_key: "invoicing.nav.title"')
      expect(File.read(target.join("config/module.rb"))).to include('path: "/billing"').and include('permission_prefixes: [ "billing", "shared" ]')
      expect(File.read(target.join("app/controllers/rafelo/invoicing/widgets_controller.rb"))).to include('render_page "invoicing/widgets/index"').and include('t("invoicing.widgets.title")').and include("route(:invoicing").and include('name: "invoicing/write"')
      expect(File.read(target.join("app/props/rafelo/invoicing/widgets_index_props.rb"))).to include('I18n.t("invoicing.widgets.title")')
      expect(File.read(target.join("app/public/rafelo/invoicing/permissions.rb"))).to include("module Invoicing").and include('"billing:widgets:read"')
      expect(File.read(target.join("README.md"))).to eq("# invoicing\n\nThe invoicing module.\n")
      expect(File.read(target.join("AGENTS.md"))).to eq("# Rafelo::Invoicing\n\nThe invoicing module.\n")
      expect(File.read(target.join("tsconfig.json"))).to include("tmp/tsc/invoicing")
      expect(File.read(target.join("e2e/widgets.spec.ts"))).to include('test.describe("invoicing"').and include('getByTestId("invoicing.widgets.index.list")').and include('"/en/billing/widgets"')

      spec = File.read(root.join("spec/requests/invoicing/widgets_spec.rb"))
      expect(spec).to include('"invoicing/widgets"').and include('get "/en/billing/widgets"').and include('within_budgets("invoicing/widgets/index")').and include('"billing:widgets:read"').and include("engines/invoicing/spec/fixtures")
      root_e2e = File.read(root.join("e2e/invoicing/widgets.spec.ts"))
      expect(root_e2e).to include('test.describe("invoicing"').and include('getByTestId("invoicing.widgets.index.list")').and include('"/en/billing/widgets"')

      dependent_package = YAML.safe_load(File.read(root.join("engines/shipper/package.yml")))
      expect(dependent_package["dependencies"]).to eq([ "engines/core", "engines/invoicing" ])
      dependent_frontend = File.read(root.join("engines/shipper/app/frontend/public/index.ts"))
      expect(dependent_frontend).to include("@invoicing/public")
      expect(dependent_frontend).not_to include("@billing")
      dependent_model = File.read(root.join("engines/shipper/app/models/rafelo/shipper/shipment.rb"))
      expect(dependent_model).to include("Rafelo::Invoicing::Widget")
      expect(dependent_model).not_to include("Rafelo::Billing")
      aliases = File.read(root.join("config/frontend_aliases.mts"))
      expect(aliases).to include('find: "@invoicing"').and include("engines/invoicing/app/frontend")
      expect(aliases).not_to include("@billing")

      allowed = lambda do |path, line|
        relative = path.delete_prefix("#{root}/")
        case relative
        when "engines/invoicing/config/module.rb"
          line.match?(/path:|permission_prefixes:/)
        when "engines/invoicing/config/permissions.yml", "config/grants.json", "engines/invoicing/config/initializers/legacy_constants.rb"
          true
        when "engines/invoicing/package.yml"
          line.include?("legacy_table_prefix")
        when "engines/invoicing/app/public/rafelo/invoicing/permissions.rb", "engines/invoicing/app/frontend/permissions.generated.ts"
          line.include?("billing:widgets:read")
        when "spec/requests/invoicing/widgets_spec.rb"
          line.include?("/en/billing/widgets") || line.include?("billing:widgets:read")
        when "e2e/invoicing/widgets.spec.ts", "engines/invoicing/e2e/widgets.spec.ts"
          line.include?("/en/billing/widgets")
        else
          false
        end
      end
      leftovers = Dir[root.join("**/*")].select { |path| File.file?(path) }.flat_map do |path|
        File.readlines(path).each_with_index.filter_map do |line, index|
          next unless line.include?("billing")
          next if allowed.call(path, line)

          "#{path.delete_prefix("#{root}/")}:#{index + 1}: #{line.strip}"
        end
      end
      expect(leftovers).to be_empty, "leftover references:\n#{leftovers.join("\n")}"
    end
  end

  it "restores the tree when rename fails mid-run" do
    Dir.mktmpdir do |dir|
      root = Pathname(dir)
      src = root.join("engines/billing")
      FileUtils.mkdir_p(src.join("config/initializers"))
      FileUtils.mkdir_p(src.join("lib/rafelo/billing"))
      File.write(src.join("package.yml"), YAML.dump("enforce_dependencies" => "strict", "dependencies" => []))
      File.write(src.join("config/ratchets.yml"), YAML.dump("eslint_disable" => 0))
      File.write(src.join("config/module.rb"), "Rafelo::Core::Modules.register(key: :billing, engine: Object, path: \"/billing\", permission_prefixes: [\"billing\"], nav: { order: 10 })\n")
      File.write(src.join("config/permissions.yml"), YAML.dump("billing" => { "widgets" => [ "read" ] }))
      File.write(src.join("lib/rafelo/billing/engine.rb"), "module Rafelo::Billing; class Engine < Rails::Engine; end; end\n")
      before = Dir[root.join("**/*")].select { |p| File.file?(p) }.sort.map { |p| [ p, File.binread(p) ] }

      failing = Class.new(described_class) do
        private

        def write_legacy_constants(_engine_root)
          raise "boom"
        end
      end

      expect {
        begin
          failing.start([ "billing", "invoicing", "--skip-post-write" ], destination_root: dir)
        rescue SystemExit, Thor::Error
          nil
        end
      }.not_to raise_error

      after = Dir[root.join("**/*")].select { |p| File.file?(p) }.sort.map { |p| [ p, File.binread(p) ] }
      expect(after).to eq(before)
    end
  end
end
