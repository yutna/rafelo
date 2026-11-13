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
end
