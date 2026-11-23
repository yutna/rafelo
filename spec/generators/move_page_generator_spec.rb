require "rails_helper"
require "tmpdir"
require "yaml"
require Rails.root.join("engines/core/lib/generators/rafelo/move_page_generator")

RSpec.describe Rafelo::Generators::MovePageGenerator do
  def write_file(root, relative, body)
    path = root.join(relative)
    FileUtils.mkdir_p(path.dirname)
    File.write(path, body)
  end

  def write_engine(root, name, path:, routes:, permissions:, module_rb_extra: "", prefixes: nil)
    dir = root.join("engines", name)
    FileUtils.mkdir_p(dir.join("config"))
    FileUtils.mkdir_p(dir.join("app/controllers/rafelo/#{name}"))
    File.write(dir.join("config/routes.rb"), routes)
    File.write(dir.join("config/permissions.yml"), YAML.dump(permissions))
    prefixes ||= [ name ]
    File.write(dir.join("config/module.rb"), <<~RUBY)
      Rafelo::Core::Modules.register(
        key: :#{name},
        engine: Object,
        path: "#{path}",
        permission_prefixes: [#{prefixes.map { |prefix| "\"#{prefix}\"" }.join(", ")}],
        nav: { order: 10 }
      #{module_rb_extra}  )
    RUBY
  end

  it "moves a resource, keeps permission keys stable, adds legacy path, and reassigns root" do
    Dir.mktmpdir do |dir|
      root = Pathname(dir)
      write_engine(root, "billing",
        path: "/billing",
        routes: "Rafelo::Billing::Engine.routes.draw do\n  resources :widgets\n  root to: \"widgets#index\"\nend\n",
        permissions: { "billing" => { "widgets" => [ "read" ] } })
      write_engine(root, "payments",
        path: "/payments",
        routes: "Rafelo::Payments::Engine.routes.draw do\nend\n",
        permissions: { "payments" => {} })
      FileUtils.mkdir_p(root.join("engines/billing/app/frontend/pages/widgets"))
      File.write(root.join("engines/billing/app/frontend/pages/widgets/index.tsx"), 'export default "billing/widgets"')

      described_class.start([ "billing", "payments", "widgets", "--skip-post-write" ], destination_root: dir)

      expect(root.join("engines/billing/app/frontend/pages/widgets")).not_to exist
      expect(root.join("engines/payments/app/frontend/pages/widgets/index.tsx")).to exist
      src_routes = File.read(root.join("engines/billing/config/routes.rb"))
      expect(src_routes).not_to include("resources :widgets")
      tgt_routes = File.read(root.join("engines/payments/config/routes.rb"))
      expect(tgt_routes).to include("resources :widgets")
      expect(tgt_routes).to include('root to: "widgets#index"')

      src_perm = YAML.safe_load(File.read(root.join("engines/billing/config/permissions.yml")))
      tgt_perm = YAML.safe_load(File.read(root.join("engines/payments/config/permissions.yml")))
      expect(src_perm.dig("billing", "widgets")).to be_nil
      expect(tgt_perm.dig("billing", "widgets")).to eq([ "read" ])
      expect(tgt_perm.dig("payments", "widgets")).to be_nil

      mod_rb = File.read(root.join("engines/payments/config/module.rb"))
      expect(mod_rb).to include('legacy_paths')
      expect(mod_rb).to include('/billing/widgets')
      expect(mod_rb).to include('"billing"')

      redirect_spec = root.join("spec/requests/payments/widgets_legacy_redirect_spec.rb")
      expect(redirect_spec).to exist
      expect(File.read(redirect_spec)).to include('get "/#{I18n.default_locale}/billing/widgets"')
      expect(File.read(redirect_spec)).to include('redirect_to("/#{I18n.default_locale}/payments/widgets")')
    end
  end

  it "keeps the stable permission prefix and route path after a rename" do
    Dir.mktmpdir do |dir|
      root = Pathname(dir)
      write_engine(root, "invoicing",
        path: "/billing",
        routes: "Rafelo::Invoicing::Engine.routes.draw do\n  resources :widgets\nend\n",
        permissions: { "billing" => { "widgets" => [ "read" ] } },
        prefixes: [ "billing" ])
      write_engine(root, "payments",
        path: "/payments",
        routes: "Rafelo::Payments::Engine.routes.draw do\nend\n",
        permissions: { "payments" => {} })
      FileUtils.mkdir_p(root.join("engines/invoicing/app/frontend/pages/widgets"))
      File.write(root.join("engines/invoicing/app/frontend/pages/widgets/index.tsx"), 'export default "billing/widgets"')

      described_class.start([ "invoicing", "payments", "widgets", "--skip-post-write" ], destination_root: dir)

      target_permissions = YAML.safe_load(File.read(root.join("engines/payments/config/permissions.yml")))
      expect(target_permissions.dig("billing", "widgets")).to eq([ "read" ])
      expect(target_permissions).not_to have_key("invoicing")

      module_rb = File.read(root.join("engines/payments/config/module.rb"))
      expect(module_rb).to include('legacy_paths: { "/billing/widgets"')
      expect(module_rb).to include('"billing"')

      redirect_spec = File.read(root.join("spec/requests/payments/widgets_legacy_redirect_spec.rb"))
      expect(redirect_spec).to include('get "/#{I18n.default_locale}/billing/widgets"')
      expect(redirect_spec).to include('redirect_to("/#{I18n.default_locale}/payments/widgets")')
    end
  end

  it "moves the whole slice and leaves no slice file behind" do
    Dir.mktmpdir do |dir|
      root = Pathname(dir)
      write_engine(root, "billing",
        path: "/billing",
        routes: "Rafelo::Billing::Engine.routes.draw do\n  resources :widgets\n  root to: \"widgets#index\"\nend\n",
        permissions: { "billing" => { "widgets" => [ "read" ] } })
      write_engine(root, "payments",
        path: "/payments",
        routes: "Rafelo::Payments::Engine.routes.draw do\nend\n",
        permissions: { "payments" => { "widgets" => [ "read" ] } })
      write_file(root, "engines/billing/config/locales/en.yml", YAML.dump("en" => { "billing" => { "widgets" => { "title" => "Widgets" } } }))
      write_file(root, "engines/billing/config/locales/th.yml", YAML.dump("th" => { "billing" => { "widgets" => { "title" => "วิดเจ็ต" } } }))
      write_file(root, "engines/payments/config/locales/en.yml", YAML.dump("en" => { "payments" => { "nav" => { "title" => "Payments" } } }))
      write_file(root, "engines/payments/config/locales/th.yml", YAML.dump("th" => { "payments" => { "nav" => { "title" => "การชำระเงิน" } } }))
      write_file(root, "engines/billing/config/budgets.yml", YAML.dump("pages" => { "billing/widgets/index" => { "sql_queries_per_request" => 2 } }))
      write_file(root, "engines/payments/config/budgets.yml", YAML.dump("pages" => {}))
      write_file(root, "engines/billing/package.yml", YAML.dump("dependencies" => []))
      write_file(root, "engines/payments/package.yml", YAML.dump("dependencies" => []))
      write_file(root, "engines/payments/config/ratchets.yml", YAML.dump("legacy_table_prefixes" => 0))
      write_file(root, "engines/billing/db/migrate/20260101000000_create_widgets.rb", "# frozen_string_literal: true\n")

      engine_slice = {
        "app/gateways/rafelo/billing/widgets_gateway.rb" => "module Rafelo\n  module Billing\n    class WidgetsGateway; end\n  end\nend\n",
        "app/models/rafelo/billing/widget.rb" => "module Rafelo\n  module Billing\n    Widget = Data.define(:id)\n  end\nend\n",
        "app/jobs/rafelo/billing/widget_export_job.rb" => "module Rafelo\n  module Billing\n    class WidgetExportJob; end\n  end\nend\n",
        "app/controllers/rafelo/billing/widgets_controller.rb" => "module Rafelo\n  module Billing\n    class WidgetsController; end\n  end\nend\n",
        "app/policies/rafelo/billing/widget_policy.rb" => "module Rafelo\n  module Billing\n    class WidgetPolicy; end\n  end\nend\n",
        "app/props/rafelo/billing/widgets_index_props.rb" => "module Rafelo\n  module Billing\n    class WidgetsIndexProps; end\n  end\nend\n",
        "app/forms/rafelo/billing/widget_form.rb" => "module Rafelo\n  module Billing\n    class WidgetForm; end\n  end\nend\n",
        "app/frontend/pages/widgets/index.tsx" => "import { useBillingTranslation } from \"@billing/i18n\";\n\nexport default \"billing/widgets\";\n",
        "app/frontend/screens/widgets/index_screen.tsx" => 'export const screen = "@billing/screens/widgets";',
        "app/frontend/containers/widgets/index_container.tsx" => 'export const container = "@billing/containers/widgets";',
        "app/frontend/components/widgets/list.tsx" => 'export const list = "@billing/components/widgets";',
        "app/frontend/hooks/widgets/use_widgets.ts" => 'export const hook = "@billing/hooks/widgets";',
        "app/frontend/domain/widget/widget.ts" => "export type Widget = { id: string };",
        "app/frontend/forms/widget/widget_form.ts" => "export type WidgetForm = { name: string };",
        "config/contracts/pages/widgets/index.json" => "{}\n",
        "spec/fixtures/upstream/widgets/index.json" => '{"items":[]}',
        "spec/widget_spec.rb" => "RSpec.describe Rafelo::Billing::Widget do\nend\n",
        "spec/requests/widgets_spec.rb" => "RSpec.describe \"billing/widgets\" do\nend\n",
        "e2e/widgets.spec.ts" => 'test("widgets", () => {});'
      }
      engine_slice.each { |relative, body| write_file(root, "engines/billing/#{relative}", body) }
      write_file(root, "spec/requests/billing/widgets_spec.rb", <<~RUBY)
        RSpec.describe "billing/widgets" do
          let(:fixture) { Rails.root.join("engines/billing/spec/fixtures/upstream/widgets/index.json") }
          let(:page_key) { "billing/widgets/index" }
        end
      RUBY
      write_file(root, "e2e/billing/widgets.spec.ts", "test(\"/en/billing/widgets\", () => {});\n")
      write_file(root, "engines/billing/app/frontend/i18n.ts", <<~TS)
        import i18next from "i18next";

        export function useBillingTranslation() {
          return (key: string) => i18next.t(key, { ns: "billing" });
        }
      TS

      described_class.start([ "billing", "payments", "widgets", "--skip-post-write" ], destination_root: dir)

      leftovers = engine_slice.keys.select { |relative| File.exist?(root.join("engines/billing", relative)) }
      expect(leftovers).to be_empty
      app_ns = Rails.application.class.module_parent_name.underscore
      engine_slice.each_key do |relative|
        target = relative.sub("/#{app_ns}/billing/", "/#{app_ns}/payments/")
        expect(root.join("engines/payments", target)).to exist
      end
      expect(root.join("spec/requests/billing/widgets_spec.rb")).not_to exist
      moved_spec = File.read(root.join("spec/requests/payments/widgets_spec.rb"))
      expect(moved_spec).to include("engines/payments/spec/fixtures/upstream/widgets/index.json")
      expect(moved_spec).to include('"payments/widgets/index"')
      moved_page = File.read(root.join("engines/payments/app/frontend/pages/widgets/index.tsx"))
      expect(moved_page).to include("@payments/i18n")
      expect(moved_page).to include("usePaymentsTranslation")
      hook = File.read(root.join("engines/payments/app/frontend/i18n.ts"))
      expect(hook).to include("usePaymentsTranslation")
      expect(hook).to include('ns: "payments"')
      expect(root.join("engines/billing/app/frontend/i18n.ts")).to exist
      expect(File.read(root.join("e2e/payments/widgets.spec.ts"))).to include("/en/payments/widgets")
      expect(root.join("e2e/billing/widgets.spec.ts")).not_to exist
      expect(root.join("engines/billing/db/migrate/20260101000000_create_widgets.rb")).to exist

      en = YAML.safe_load(File.read(root.join("engines/payments/config/locales/en.yml")))
      expect(en.dig("en", "payments", "widgets", "title")).to eq("Widgets")
      expect(YAML.safe_load(File.read(root.join("engines/billing/config/locales/en.yml"))).dig("en", "billing", "widgets")).to be_nil
      budgets = YAML.safe_load(File.read(root.join("engines/payments/config/budgets.yml")))
      expect(budgets.dig("pages", "payments/widgets/index", "sql_queries_per_request")).to eq(2)
      expect(YAML.safe_load(File.read(root.join("engines/billing/config/budgets.yml"))).dig("pages", "billing/widgets/index")).to be_nil
      permissions = YAML.safe_load(File.read(root.join("engines/payments/config/permissions.yml")))
      expect(permissions.dig("billing", "widgets")).to eq([ "read" ])
      expect(permissions.dig("payments", "widgets")).to be_nil
      package = YAML.safe_load(File.read(root.join("engines/payments/package.yml")))
      expect(package.dig("metadata", "legacy_table_prefix")).to eq("billing")
      expect(YAML.safe_load(File.read(root.join("engines/payments/config/ratchets.yml")))["legacy_table_prefixes"]).to eq(1)
    end
  end

  it "reassigns source root to the next remaining index resource when moved resource was root" do
    Dir.mktmpdir do |dir|
      root = Pathname(dir)
      write_engine(root, "billing",
        path: "/billing",
        routes: "Rafelo::Billing::Engine.routes.draw do\n  resources :widgets\n  resources :invoices\n  root to: \"widgets#index\"\nend\n",
        permissions: { "billing" => { "widgets" => [ "read" ], "invoices" => [ "read" ] } })
      write_engine(root, "payments",
        path: "/payments",
        routes: "Rafelo::Payments::Engine.routes.draw do\nend\n",
        permissions: { "payments" => {} })
      FileUtils.mkdir_p(root.join("engines/billing/app/frontend/pages/widgets"))
      File.write(root.join("engines/billing/app/frontend/pages/widgets/index.tsx"), 'export default "billing/widgets"')

      described_class.start([ "billing", "payments", "widgets", "--skip-post-write" ], destination_root: dir)

      src_routes = File.read(root.join("engines/billing/config/routes.rb"))
      expect(src_routes).to include('root to: "invoices#index"')
      expect(src_routes).not_to include("resources :widgets")
    end
  end

  it "removes source root when moved resource was root and no index resource remains" do
    Dir.mktmpdir do |dir|
      root = Pathname(dir)
      write_engine(root, "billing",
        path: "/billing",
        routes: "Rafelo::Billing::Engine.routes.draw do\n  resources :widgets\n  resources :audits, only: [:show]\n  root to: \"widgets#index\"\nend\n",
        permissions: { "billing" => { "widgets" => [ "read" ], "audits" => [ "read" ] } })
      write_engine(root, "payments",
        path: "/payments",
        routes: "Rafelo::Payments::Engine.routes.draw do\nend\n",
        permissions: { "payments" => {} })
      FileUtils.mkdir_p(root.join("engines/billing/app/frontend/pages/widgets"))
      File.write(root.join("engines/billing/app/frontend/pages/widgets/index.tsx"), 'export default "billing/widgets"')

      described_class.start([ "billing", "payments", "widgets", "--skip-post-write" ], destination_root: dir)

      src_routes = File.read(root.join("engines/billing/config/routes.rb"))
      expect(src_routes).not_to include("root to:")
      expect(src_routes).to include("resources :audits")
      expect(src_routes).not_to include("resources :widgets")
    end
  end

  it "restores the tree when move fails mid-run" do
    Dir.mktmpdir do |dir|
      root = Pathname(dir)
      write_engine(root, "billing",
        path: "/billing",
        routes: "Rafelo::Billing::Engine.routes.draw do\n  resources :widgets\nend\n",
        permissions: { "billing" => { "widgets" => [ "read" ] } })
      write_engine(root, "payments",
        path: "/payments",
        routes: "Rafelo::Payments::Engine.routes.draw do\nend\n",
        permissions: { "payments" => {} })
      FileUtils.mkdir_p(root.join("engines/billing/app/frontend/pages/widgets"))
      File.write(root.join("engines/billing/app/frontend/pages/widgets/index.tsx"), 'export default "billing/widgets"')
      before = Dir[root.join("**/*")].select { |p| File.file?(p) }.sort.map { |p| [ p, File.binread(p) ] }

      failing = Class.new(described_class) do
        private

        def add_legacy_path
          raise "boom"
        end
      end

      expect {
        begin
          failing.start([ "billing", "payments", "widgets", "--skip-post-write" ], destination_root: dir)
        rescue SystemExit, Thor::Error
          nil
        end
      }.not_to raise_error

      after = Dir[root.join("**/*")].select { |p| File.file?(p) }.sort.map { |p| [ p, File.binread(p) ] }
      expect(after).to eq(before)
    end
  end

  it "refuses to move a resource that is not present in the source module" do
    Dir.mktmpdir do |dir|
      root = Pathname(dir)
      write_engine(root, "billing",
        path: "/billing",
        routes: "Rafelo::Billing::Engine.routes.draw do\nend\n",
        permissions: { "billing" => {} })
      write_engine(root, "payments",
        path: "/payments",
        routes: "Rafelo::Payments::Engine.routes.draw do\nend\n",
        permissions: { "payments" => {} })
      before = Dir[root.join("**/*")].select { |p| File.file?(p) }.sort.map { |p| [ p, File.binread(p) ] }

      expect {
        begin
          described_class.start([ "billing", "payments", "widgets", "--skip-post-write" ], destination_root: dir)
        rescue SystemExit, Thor::Error
          nil
        end
      }.not_to raise_error

      after = Dir[root.join("**/*")].select { |p| File.file?(p) }.sort.map { |p| [ p, File.binread(p) ] }
      expect(after).to eq(before)
    end
  end

  it "refuses to move when the resource already exists in the target module" do
    Dir.mktmpdir do |dir|
      root = Pathname(dir)
      write_engine(root, "billing",
        path: "/billing",
        routes: "Rafelo::Billing::Engine.routes.draw do\n  resources :widgets\nend\n",
        permissions: { "billing" => { "widgets" => [ "read" ] } })
      write_engine(root, "payments",
        path: "/payments",
        routes: "Rafelo::Payments::Engine.routes.draw do\n  resources :widgets\nend\n",
        permissions: { "payments" => { "widgets" => [ "read" ] } })
      FileUtils.mkdir_p(root.join("engines/billing/app/frontend/pages/widgets"))
      File.write(root.join("engines/billing/app/frontend/pages/widgets/index.tsx"), 'export default "billing/widgets"')
      before = Dir[root.join("**/*")].select { |p| File.file?(p) }.sort.map { |p| [ p, File.binread(p) ] }

      expect {
        begin
          described_class.start([ "billing", "payments", "widgets", "--skip-post-write" ], destination_root: dir)
        rescue SystemExit, Thor::Error
          nil
        end
      }.not_to raise_error

      after = Dir[root.join("**/*")].select { |p| File.file?(p) }.sort.map { |p| [ p, File.binread(p) ] }
      expect(after).to eq(before)
      expect(File.read(root.join("engines/billing/config/routes.rb"))).to include("resources :widgets")
      expect(File.read(root.join("engines/payments/config/routes.rb"))).to include("resources :widgets")
    end
  end
end
