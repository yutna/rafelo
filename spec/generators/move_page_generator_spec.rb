require "rails_helper"
require "tmpdir"
require "yaml"
require Rails.root.join("engines/core/lib/generators/rafelo/move_page_generator")

RSpec.describe Rafelo::Generators::MovePageGenerator do
  def write_engine(root, name, path:, routes:, permissions:, module_rb_extra: "")
    dir = root.join("engines", name)
    FileUtils.mkdir_p(dir.join("config"))
    FileUtils.mkdir_p(dir.join("app/controllers/rafelo/#{name}"))
    File.write(dir.join("config/routes.rb"), routes)
    File.write(dir.join("config/permissions.yml"), YAML.dump(permissions))
    File.write(dir.join("config/module.rb"), <<~RUBY)
      Rafelo::Core::Modules.register(
        key: :#{name},
        engine: Object,
        path: "#{path}",
        permission_prefixes: ["#{name}"],
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
      expect(tgt_perm.dig("payments", "widgets")).to eq([ "read" ])

      mod_rb = File.read(root.join("engines/payments/config/module.rb"))
      expect(mod_rb).to include('legacy_paths')
      expect(mod_rb).to include('/billing/widgets')
      expect(mod_rb).to include('"billing"')
    end
  end
end
