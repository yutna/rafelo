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
end
