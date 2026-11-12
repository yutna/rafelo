require "rails_helper"

RSpec.describe Rafelo::Core::Modules do
  after { described_class.reset! }

  it "registers a module with defaults" do
    entry = described_class.register(key: :billing, engine: Class.new)

    expect(entry.path).to eq("/billing")
    expect(entry.permission_prefixes).to eq([ "billing" ])
    expect(described_class.fetch(:billing)).to eq(entry)
  end

  it "rejects a duplicate key" do
    described_class.register(key: :billing, engine: Class.new)
    described_class.register(key: :billing, engine: Class.new, path: "/other")

    expect { described_class.validate! }.to raise_error(ArgumentError, /duplicate module key/)
  end

  it "rejects a duplicate path" do
    described_class.register(key: :billing, engine: Class.new)
    described_class.register(key: :payments, engine: Class.new, path: "/billing")

    expect { described_class.validate! }.to raise_error(ArgumentError, /duplicate module path/)
  end

  it "rejects a reserved key or first path segment" do
    expect { described_class.register(key: :core, engine: Class.new) }.to raise_error(ArgumentError, /reserved/)
    expect { described_class.register(key: :auth, engine: Class.new) }.to raise_error(ArgumentError, /reserved/)
    expect { described_class.register(key: :safe, engine: Class.new, path: "/core/extra") }.to raise_error(ArgumentError, /reserved/)
    expect { described_class.register(key: :safe, engine: Class.new, path: "/sign_in/extra") }.to raise_error(ArgumentError, /reserved/)
    expect { described_class.register(key: :safe, engine: Class.new, path: "/up/extra") }.to raise_error(ArgumentError, /reserved/)
  end

  it "rejects a locale-shaped key or path" do
    expect { described_class.register(key: :en, engine: Class.new) }.to raise_error(ArgumentError, /reserved/)
    expect { described_class.register(key: :safe, engine: Class.new, path: "/th") }.to raise_error(ArgumentError, /reserved/)
  end

  it "rejects a duplicate navigation order" do
    described_class.register(key: :billing, engine: Class.new, nav: { order: 10 })
    described_class.register(key: :payments, engine: Class.new, path: "/payments", nav: { order: 10 })

    expect { described_class.validate! }.to raise_error(ArgumentError, /navigation order/)
  end
end
