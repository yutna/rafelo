require "rails_helper"

RSpec.describe Rafelo::Core::Modules do
  after { described_class.reset! }

  it "registers a module with defaults" do
    entry = described_class.register(key: :ledger, engine: ->(_env) { [ 200, {}, [ "ok" ] ] })

    expect(entry.path).to eq("/ledger")
    expect(entry.permission_prefixes).to eq([ "ledger" ])
    expect(described_class.fetch(:ledger)).to eq(entry)
  end

  it "rejects a duplicate key" do
    described_class.register(key: :ledger, engine: ->(_env) { [ 200, {}, [ "ok" ] ] })
    described_class.register(key: :ledger, engine: ->(_env) { [ 200, {}, [ "ok" ] ] }, path: "/other")

    expect { described_class.validate! }.to raise_error(ArgumentError, /duplicate module key/)
  end

  it "rejects a duplicate path" do
    described_class.register(key: :ledger, engine: ->(_env) { [ 200, {}, [ "ok" ] ] })
    described_class.register(key: :payments, engine: ->(_env) { [ 200, {}, [ "ok" ] ] }, path: "/ledger")

    expect { described_class.validate! }.to raise_error(ArgumentError, /duplicate module path/)
  end

  it "rejects a reserved key or first path segment" do
    expect { described_class.register(key: :core, engine: ->(_env) { [ 200, {}, [ "ok" ] ] }) }.to raise_error(ArgumentError, /reserved/)
    expect { described_class.register(key: :auth, engine: ->(_env) { [ 200, {}, [ "ok" ] ] }) }.to raise_error(ArgumentError, /reserved/)
    expect { described_class.register(key: :safe, engine: ->(_env) { [ 200, {}, [ "ok" ] ] }, path: "/core/extra") }.to raise_error(ArgumentError, /reserved/)
    expect { described_class.register(key: :safe, engine: ->(_env) { [ 200, {}, [ "ok" ] ] }, path: "/sign_in/extra") }.to raise_error(ArgumentError, /reserved/)
    expect { described_class.register(key: :safe, engine: ->(_env) { [ 200, {}, [ "ok" ] ] }, path: "/up/extra") }.to raise_error(ArgumentError, /reserved/)
  end

  it "rejects a locale-shaped key or path" do
    expect { described_class.register(key: :en, engine: ->(_env) { [ 200, {}, [ "ok" ] ] }) }.to raise_error(ArgumentError, /reserved/)
    expect { described_class.register(key: :safe, engine: ->(_env) { [ 200, {}, [ "ok" ] ] }, path: "/th") }.to raise_error(ArgumentError, /reserved/)
  end

  it "rejects a key or first segment added by the app routes" do
    fake_route = Struct.new(:name, :path).new(nil, Struct.new(:spec).new("/reports(.:format)"))
    allow(Rails.application.routes).to receive(:routes).and_return([ fake_route ])

    engine = ->(_env) { [ 200, {}, [ "ok" ] ] }
    expect { described_class.register(key: :reports, engine: engine) }.to raise_error(ArgumentError, /reserved/)
    expect { described_class.register(key: :safe, engine: engine, path: "/reports/extra") }.to raise_error(ArgumentError, /reserved/)
  end

  it "does not reject a module because its own mounted route exists" do
    described_class.register(key: :ledger, engine: ->(_env) { [ 200, {}, [ "ok" ] ] })
    fake_route = Struct.new(:name, :path).new("ledger", Struct.new(:spec).new("/:locale/ledger(.:format)"))
    allow(Rails.application.routes).to receive(:routes).and_return([ fake_route ])

    expect { described_class.validate! }.not_to raise_error
  end

  it "checks a boot-registered module against an app route with the same first segment" do
    engine = ->(_env) { [ 200, {}, [ "ok" ] ] }
    described_class.register(key: :safe, engine: engine, path: "/reports/extra")
    fake_route = Struct.new(:name, :path).new(nil, Struct.new(:spec).new("/reports(.:format)"))
    allow(Rails.application.routes).to receive(:routes).and_return([ fake_route ])

    expect { described_class.validate! }.to raise_error(ArgumentError, /path is reserved: reports/)
  end

  it "rejects a duplicate navigation order" do
    described_class.register(key: :ledger, engine: ->(_env) { [ 200, {}, [ "ok" ] ] }, nav: { order: 10 })
    described_class.register(key: :payments, engine: ->(_env) { [ 200, {}, [ "ok" ] ] }, path: "/payments", nav: { order: 10 })

    expect { described_class.validate! }.to raise_error(ArgumentError, /navigation order/)
  end

  it "knows when an engine has a root route" do
    with_root = Class.new do
      def self.routes = Struct.new(:routes).new([ Struct.new(:name).new("root") ])
    end
    without_root = Class.new do
      def self.routes = Struct.new(:routes).new([])
    end

    fake_route = Struct.new(:name, :path).new("ledger", Struct.new(:spec).new("/:locale/ledger(.:format)"))
    ledger = described_class.register(key: :ledger, engine: with_root)
    payments = described_class.register(key: :payments, engine: without_root, path: "/payments")
    unmounted = described_class.register(key: :reports, engine: with_root, path: "/reports")
    fake_route = Struct.new(:name, :path).new("ledger", Struct.new(:spec).new("/:locale/ledger(.:format)"))
    allow(Rails.application.routes).to receive(:routes).and_return([ fake_route ])

    expect(ledger.root_route?).to be(true)
    expect(payments.root_route?).to be(false)
    expect(unmounted.root_route?).to be(false)
  end

  it "rejects a permission key two modules both declare" do
    Dir.mktmpdir("rafelo-module-a-") do |first|
      Dir.mktmpdir("rafelo-module-b-") do |second|
        [ first, second ].each do |root|
          FileUtils.mkdir_p(File.join(root, "config"))
          File.write(File.join(root, "config", "permissions.yml"), "billing:\n  invoice: [read]\n")
        end
        first_engine = Struct.new(:root).new(Pathname.new(first))
        second_engine = Struct.new(:root).new(Pathname.new(second))

        described_class.register(key: :ledger, engine: first_engine)
        described_class.register(key: :payments, engine: second_engine, path: "/payments")

        expect { described_class.validate! }.to raise_error(ArgumentError, /permission key billing:invoice:read/)
      end
    end
  end

  it "maps every module icon to a design-system icon name" do
    icon_map = Rails.root.join("engines/design_system/app/frontend/icon.tsx").read.scan(/^  ([a-z_]+):/).flatten
    module_icons = Dir[Rails.root.join("engines/*/config/module.rb")].flat_map do |path|
      File.read(path).scan(/icon:\s*"([a-z_]+)"/).flatten
    end

    expect(module_icons - icon_map).to be_empty
  end

  it "finds a module by its locale-prefixed first path segment" do
    entry = described_class.register(key: :ledger, engine: ->(_env) { [ 200, {}, [ "ok" ] ] })

    expect(described_class.for_path("/en/ledger/invoices/7?tab=1")).to eq(entry)
    expect(described_class.for_path("/th/ledger")).to eq(entry)
    expect(described_class.for_path("/ledger")).to eq(entry)
    expect(described_class.for_path("/en/other/ledger")).to be_nil
    expect(described_class.for_path("/en")).to be_nil
  end
end
