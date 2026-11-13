require "rails_helper"
require "tmpdir"
require Rails.root.join("engines/core/lib/generators/rafelo/page_generator")

RSpec.describe Rafelo::Generators::PageGenerator do
  before do
    allow_any_instance_of(described_class).to receive(:post_write)
  end

  it "does not expose the post-write escape hatch" do
    expect(described_class.class_options).not_to have_key(:skip_post_write)
  end

  it "refuses a resource the module already has without adding files" do
    Dir.mktmpdir do |dir|
      root = Pathname(dir)
      FileUtils.mkdir_p(root.join("engines/billing/config"))
      routes = "Rafelo::Billing::Engine.routes.draw do\n  resources :widgets\nend\n"
      File.write(root.join("engines/billing/config/routes.rb"), routes)

      expect {
        begin
          described_class.start([ "billing", "widgets" ], destination_root: dir)
        rescue SystemExit, Thor::Error
          nil
        end
      }.not_to change { Dir[root.join("**/*")].sort }

      expect(File.read(root.join("engines/billing/config/routes.rb"))).to eq(routes)
    end
  end

  it "refuses when page artifacts already exist even without a route entry" do
    Dir.mktmpdir do |dir|
      root = Pathname(dir)
      FileUtils.mkdir_p(root.join("engines/billing/config"))
      FileUtils.mkdir_p(root.join("engines/billing/app/frontend/pages/widgets"))
      routes = "Rafelo::Billing::Engine.routes.draw do\nend\n"
      File.write(root.join("engines/billing/config/routes.rb"), routes)

      expect {
        begin
          described_class.start([ "billing", "widgets" ], destination_root: dir)
        rescue SystemExit, Thor::Error
          nil
        end
      }.not_to change { Dir[root.join("**/*")].sort }

      expect(File.read(root.join("engines/billing/config/routes.rb"))).to eq(routes)
    end
  end

  it "refuses when gateway, props, or fixture artifacts already exist" do
    Dir.mktmpdir do |dir|
      root = Pathname(dir)
      FileUtils.mkdir_p(root.join("engines/billing/config"))
      FileUtils.mkdir_p(root.join("engines/billing/app/gateways/rafelo/billing"))
      File.write(root.join("engines/billing/app/gateways/rafelo/billing/widgets_gateway.rb"), "# existing\n")
      routes = "Rafelo::Billing::Engine.routes.draw do\nend\n"
      File.write(root.join("engines/billing/config/routes.rb"), routes)
      before = Dir[root.join("**/*")].sort.map { |p| [ p, File.file?(p) ? File.binread(p) : :dir ] }

      expect {
        begin
          described_class.start([ "billing", "widgets" ], destination_root: dir)
        rescue SystemExit, Thor::Error
          nil
        end
      }.not_to raise_error

      after = Dir[root.join("**/*")].sort.map { |p| [ p, File.file?(p) ? File.binread(p) : :dir ] }
      expect(after).to eq(before)
      expect(File.read(root.join("engines/billing/config/routes.rb"))).to eq(routes)
    end
  end

  it "rolls back generated files when a write step fails" do
    Dir.mktmpdir do |dir|
      root = Pathname(dir)
      FileUtils.mkdir_p(root.join("engines/billing/config/locales"))
      FileUtils.mkdir_p(root.join("engines/billing/config/contracts"))
      File.write(root.join("engines/billing/config/routes.rb"), "Rafelo::Billing::Engine.routes.draw do\nend\n")
      File.write(root.join("engines/billing/config/permissions.yml"), "--- {}\n")
      %w[en th].each { |loc| File.write(root.join("engines/billing/config/locales/#{loc}.yml"), "#{loc}:\n  billing: {}\n") }

      allow_any_instance_of(described_class).to receive(:write_tests).and_raise("boom")
      before = Dir[root.join("**/*")].select { |p| File.file?(p) }.sort

      expect {
        begin
          described_class.start([ "billing", "widgets" ], destination_root: dir)
        rescue SystemExit, Thor::Error
          nil
        end
      }.not_to raise_error

      after = Dir[root.join("**/*")].select { |p| File.file?(p) }.sort
      expect(after).to eq(before)
      expect(File.read(root.join("engines/billing/config/routes.rb"))).to eq("Rafelo::Billing::Engine.routes.draw do\nend\n")
    end
  end

  it "adds root route for the module's first index page" do
    Dir.mktmpdir do |dir|
      root = Pathname(dir)
      FileUtils.mkdir_p(root.join("engines/billing/config/locales"))
      FileUtils.mkdir_p(root.join("engines/billing/config/contracts"))
      File.write(root.join("engines/billing/config/routes.rb"), "Rafelo::Billing::Engine.routes.draw do\nend\n")
      File.write(root.join("engines/billing/config/permissions.yml"), "--- {}\n")
      %w[en th].each { |loc| File.write(root.join("engines/billing/config/locales/#{loc}.yml"), "#{loc}:\n  billing: {}\n") }

      described_class.start([ "billing", "widgets" ], destination_root: dir)

      routes = File.read(root.join("engines/billing/config/routes.rb"))
      expect(routes).to include('root to: "widgets#index"')
      expect(routes).to include("resources :widgets")
    end
  end

  it "generates a show slice with props, frontend files, and request spec" do
    Dir.mktmpdir do |dir|
      root = Pathname(dir)
      FileUtils.mkdir_p(root.join("engines/billing/config/locales"))
      FileUtils.mkdir_p(root.join("engines/billing/config/contracts"))
      File.write(root.join("engines/billing/config/routes.rb"), "Rafelo::Billing::Engine.routes.draw do\nend\n")
      File.write(root.join("engines/billing/config/permissions.yml"), "--- {}\n")
      %w[en th].each { |loc| File.write(root.join("engines/billing/config/locales/#{loc}.yml"), "#{loc}:\n  billing: {}\n") }

      described_class.start([ "billing", "widgets", "--actions=show" ], destination_root: dir)

      expect(root.join("engines/billing/app/controllers/rafelo/billing/widgets_controller.rb").read).to include("def show")
      expect(root.join("engines/billing/app/props/rafelo/billing/widgets_show_props.rb")).to exist
      expect(root.join("engines/billing/app/props/rafelo/billing/widgets_index_props.rb")).not_to exist
      expect(root.join("engines/billing/app/frontend/pages/widgets/show.tsx")).to exist
      expect(root.join("engines/billing/app/frontend/pages/widgets/show.schema.ts")).to exist
      expect(root.join("engines/billing/app/frontend/screens/widgets/show_screen.tsx")).to exist
      expect(root.join("engines/billing/app/frontend/pages/widgets/index.tsx")).not_to exist
      request_spec = root.join("spec/requests/billing/widgets_spec.rb").read
      expect(request_spec).to include('renders the show page contract')
      expect(request_spec).to include('match_page_schema("billing/widgets/show")')
      expect(request_spec).not_to include('renders the index page contract')
    end
  end

  it "generates an edit/update slice with props, frontend files, and request specs" do
    Dir.mktmpdir do |dir|
      root = Pathname(dir)
      FileUtils.mkdir_p(root.join("engines/billing/config/locales"))
      FileUtils.mkdir_p(root.join("engines/billing/config/contracts"))
      File.write(root.join("engines/billing/config/routes.rb"), "Rafelo::Billing::Engine.routes.draw do\nend\n")
      File.write(root.join("engines/billing/config/permissions.yml"), "--- {}\n")
      %w[en th].each { |loc| File.write(root.join("engines/billing/config/locales/#{loc}.yml"), "#{loc}:\n  billing: {}\n") }

      described_class.start([ "billing", "widgets", "--actions=edit" ], destination_root: dir)

      controller = root.join("engines/billing/app/controllers/rafelo/billing/widgets_controller.rb").read
      expect(controller).to include("def edit")
      expect(controller).to include("def update")
      expect(controller).not_to include("def index")
      expect(root.join("engines/billing/app/props/rafelo/billing/widgets_edit_props.rb")).to exist
      expect(root.join("engines/billing/app/props/rafelo/billing/widgets_index_props.rb")).not_to exist
      expect(root.join("engines/billing/app/frontend/pages/widgets/edit.tsx")).to exist
      expect(root.join("engines/billing/app/frontend/pages/widgets/edit.schema.ts")).to exist
      expect(root.join("engines/billing/app/frontend/screens/widgets/edit_screen.tsx")).to exist
      expect(root.join("engines/billing/app/frontend/pages/widgets/index.tsx")).not_to exist
      request_spec = root.join("spec/requests/billing/widgets_spec.rb").read
      expect(request_spec).to include('renders the edit page contract')
      expect(request_spec).to include('match_page_schema("billing/widgets/edit")')
      expect(request_spec).to include('redirects back with errors when update params are invalid')
      expect(request_spec).not_to include('renders the index page contract')

      en_locale = YAML.safe_load(root.join("engines/billing/config/locales/en.yml").read)
      th_locale = YAML.safe_load(root.join("engines/billing/config/locales/th.yml").read)
      expect(en_locale.dig("en", "billing", "widgets", "title")).to eq("Widgets")
      expect(en_locale.dig("en", "billing", "widgets", "edit")).to eq("Edit Widget")
      expect(th_locale.dig("th", "billing", "widgets", "title")).to eq("[th] Widgets")
      expect(th_locale.dig("th", "billing", "widgets", "edit")).to eq("[th] Edit Widget")
    end
  end

  it "generates the write gateway, form, 303 behavior and request-spec evidence" do
    Dir.mktmpdir do |dir|
      root = Pathname(dir)
      FileUtils.mkdir_p(root.join("engines/billing/config/locales"))
      FileUtils.mkdir_p(root.join("engines/billing/config/contracts"))
      File.write(root.join("engines/billing/config/routes.rb"), "Rafelo::Billing::Engine.routes.draw do\nend\n")
      File.write(root.join("engines/billing/config/permissions.yml"), "--- {}\n")
      %w[en th].each { |loc| File.write(root.join("engines/billing/config/locales/#{loc}.yml"), "#{loc}:\n  billing: {}\n") }

      described_class.start([ "billing", "widgets", "--actions=index,new,edit" ], destination_root: dir)

      gateway = root.join("engines/billing/app/gateways/rafelo/billing/widgets_gateway.rb").read
      expect(gateway).to include("def create(payload:, idempotency_key:)")
      expect(gateway).to include("def update(id:, payload:, idempotency_key:)")
      expect(gateway).to include('client.post("widgets"')
      expect(gateway).to include('client.patch("widgets/#{id}"')

      form = root.join("engines/billing/app/forms/rafelo/billing/widget_form.rb").read
      expect(form).to include("< Rafelo::Core::Form")
      expect(form).to include("validates :name, presence: true")

      controller = root.join("engines/billing/app/controllers/rafelo/billing/widgets_controller.rb").read
      expect(controller).to include("IdempotencyClaim.call")
      expect(controller).to include("gateway(Rafelo::Billing::WidgetsGateway).create")
      expect(controller).to include("gateway(Rafelo::Billing::WidgetsGateway).update")
      expect(controller).to include("Rafelo::Core::ValidationFailed")
      expect(controller).to include("resource.conflict")

      index_schema = root.join("engines/billing/app/frontend/pages/widgets/index.schema.ts").read
      expect(index_schema).to include('can: ["widgets.create"] as const')
      expect(index_schema).not_to include("billing:widgets:create")
      expect(index_schema).not_to include("paginated: false")
      index_props = root.join("engines/billing/app/props/rafelo/billing/widgets_index_props.rb").read
      expect(index_props).to include("perPage: @query.per_page")
      fixture = JSON.parse(root.join("engines/billing/spec/fixtures/upstream/widgets/index.json").read)
      expect(fixture.fetch("items").length).to eq(Rafelo::Core::ListQuery.max_per_page)
      index_screen = root.join("engines/billing/app/frontend/screens/widgets/index_screen.tsx").read
      expect(index_screen).to include('can["widgets.create"]?.allowed')

      request_spec = root.join("spec/requests/billing/widgets_spec.rb").read
      expect(request_spec).to include("renders the index page contract at the maximum page size")
      expect(request_spec).to include("creates through the gateway, redirects with 303, and replays without a second call")
      expect(request_spec).to include("upstream rejects the create")
      expect(request_spec).to include("updates through the gateway and redirects with 303")
      expect(request_spec).to include("upstream rejects the update")
      expect(request_spec).to include("a_request(:post")
    end
  end
end
