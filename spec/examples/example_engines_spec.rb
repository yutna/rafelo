require "rails_helper"

if Dir.exist?(Rails.root.join("engines/example_orders")) &&
   Dir.exist?(Rails.root.join("engines/example_customers"))
  RSpec.describe "Example engines" do
    let(:root) { Rails.root }
    let(:orders) { root.join("engines/example_orders/app/frontend") }
    let(:customers) { root.join("engines/example_customers") }

    it "keeps example_orders in the FE-01 layers with component tests" do
      %w[pages screens containers components hooks domain forms].each do |layer|
        files = Dir[orders.join(layer, "**/*.{ts,tsx}")].select { |path| File.file?(path) }
        expect(files).not_to be_empty, "example_orders is missing the #{layer} layer"
      end

      expect(orders.join("components/orders/list.test.tsx")).to exist
      expect(orders.join("components/orders/form.test.tsx")).to exist
      expect(orders.join("screens/orders/new_screen.test.tsx")).to exist
      expect(orders.join("domain/orders/order.test.ts")).to exist
      expect(orders.join("forms/orders/order_form.test.ts")).to exist
      expect(orders.join("hooks/orders/use_order_form.test.tsx")).to exist
    end

    it "keeps example domain/forms framework-free (OOP-04, FE-01)" do
      forbidden = %r{from\s+["'](?:react|@inertiajs/react|i18next|@design_system)}
      %w[domain forms].each do |layer|
        Dir[orders.join(layer, "**/*.{ts,tsx}")].each do |path|
          next if path.end_with?(".test.ts", ".test.tsx")

          expect(File.read(path)).not_to match(forbidden), "#{path} imports presentation code"
        end
      end
    end

    it "keeps example_customers in step with the rafelo:domain skeleton" do
      %w[
        config/errors.yml
        config/ratchets.yml
        config/contracts
        db/migrate
        app/frontend/domain
        app/frontend/forms
        app/frontend/hooks
        app/frontend/components
        app/frontend/public/index.ts
        app/public/rafelo/example_customers
        spec/rails_helper.rb
        spec/fixtures/upstream
        e2e
        vitest.config.mts
      ].each do |relative|
        expect(customers.join(relative)).to exist, "example_customers is missing #{relative}"
      end

      engine = File.read(customers.join("lib/rafelo/example_customers/engine.rb"))
      expect(engine).to include("rafelo_example_customers.migration_paths")
      expect(engine).to include('app.config.paths["db/migrate"] << path')
      expect(YAML.safe_load_file(customers.join("config/locales/en.yml"))).to eq(
        "en" => { "example_customers" => {} }
      )

      ratchets = YAML.safe_load_file(customers.join("config/ratchets.yml"))
      expect(ratchets.keys).to include(
        "eslint_disable",
        "rubocop_disable",
        "use_no_memo",
        "skipped_tests",
        "page_budget_overrides",
        "legacy_table_prefixes",
        "legacy_constants"
      )
    end
  end
end
