require "rails_helper"
require "tmpdir"
require Rails.root.join("engines/core/lib/generators/rafelo/page_generator")

RSpec.describe Rafelo::Generators::PageGenerator do
  it "refuses a resource the module already has without adding files" do
    Dir.mktmpdir do |dir|
      root = Pathname(dir)
      FileUtils.mkdir_p(root.join("engines/billing/config"))
      routes = "Rafelo::Billing::Engine.routes.draw do\n  resources :widgets\nend\n"
      File.write(root.join("engines/billing/config/routes.rb"), routes)

      expect {
        Rails::Generators.invoke("rafelo:page", [ "billing", "widgets", "--skip-post-write" ], destination_root: dir)
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
          described_class.start([ "billing", "widgets", "--skip-post-write" ], destination_root: dir)
        rescue SystemExit, Thor::Error
          nil
        end
      }.not_to change { Dir[root.join("**/*")].sort }

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
          described_class.start([ "billing", "widgets", "--skip-post-write" ], destination_root: dir)
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

      described_class.start([ "billing", "widgets", "--skip-post-write" ], destination_root: dir)

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

      described_class.start([ "billing", "widgets", "--actions=show", "--skip-post-write" ], destination_root: dir)

      expect(root.join("engines/billing/app/controllers/rafelo/billing/widgets_controller.rb").read).to include("def show")
      expect(root.join("engines/billing/app/props/rafelo/billing/widgets_show_props.rb")).to exist
      expect(root.join("engines/billing/app/frontend/pages/widgets/show.tsx")).to exist
      expect(root.join("engines/billing/app/frontend/pages/widgets/show.schema.ts")).to exist
      expect(root.join("engines/billing/app/frontend/screens/widgets/show_screen.tsx")).to exist
      request_spec = root.join("spec/requests/billing/widgets_spec.rb").read
      expect(request_spec).to include('renders the show page contract')
      expect(request_spec).to include('match_page_schema("billing/widgets/show")')
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

      described_class.start([ "billing", "widgets", "--actions=edit", "--skip-post-write" ], destination_root: dir)

      controller = root.join("engines/billing/app/controllers/rafelo/billing/widgets_controller.rb").read
      expect(controller).to include("def edit")
      expect(controller).to include("def update")
      expect(root.join("engines/billing/app/props/rafelo/billing/widgets_edit_props.rb")).to exist
      expect(root.join("engines/billing/app/frontend/pages/widgets/edit.tsx")).to exist
      expect(root.join("engines/billing/app/frontend/pages/widgets/edit.schema.ts")).to exist
      expect(root.join("engines/billing/app/frontend/screens/widgets/edit_screen.tsx")).to exist
      request_spec = root.join("spec/requests/billing/widgets_spec.rb").read
      expect(request_spec).to include('renders the edit page contract')
      expect(request_spec).to include('match_page_schema("billing/widgets/edit")')
      expect(request_spec).to include('redirects back with errors when update params are invalid')

      en_locale = YAML.safe_load(root.join("engines/billing/config/locales/en.yml").read)
      th_locale = YAML.safe_load(root.join("engines/billing/config/locales/th.yml").read)
      expect(en_locale.dig("en", "billing", "widgets", "title")).to eq("Widgets")
      expect(en_locale.dig("en", "billing", "widgets", "edit")).to eq("Edit Widget")
      expect(th_locale.dig("th", "billing", "widgets", "title")).to eq("[th] Widgets")
      expect(th_locale.dig("th", "billing", "widgets", "edit")).to eq("[th] Edit Widget")
    end
  end
end
