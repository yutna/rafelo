require "rails_helper"

RSpec.describe Rafelo::Core::PageProps do
  context_class = Struct.new(:viewer, :flags)

  let(:context) { context_class.new(nil, { billing: true }) }
  let(:policy) do
    Class.new(Rafelo::Core::BasePolicy) do
      def create? = true
      def export? = false
    end
  end
  let(:props_class) do
    policy_instance = policy
    Class.new(described_class) do
      policy_class policy_instance

      def initialize(context:, envelope:)
        super(context:)
        @envelope = envelope
      end

      def envelope = @envelope
    end
  end

  it "accepts exactly the envelope keys" do
    c = props_class.new(
      context: context,
      envelope: { data: {}, meta: {}, query: {}, pagination: nil, can: {} }
    )

    expect(c.to_inertia.keys).to eq(%i[data meta query pagination can])
  end

  it "rejects a missing top-level key" do
    c = props_class.new(context: context, envelope: { data: {}, meta: {}, query: {}, can: {} })

    expect { c.to_inertia }.to raise_error(ArgumentError, /missing=\[:pagination\]/)
  end

  it "rejects an extra top-level key" do
    c = props_class.new(
      context: context,
      envelope: { data: {}, meta: {}, query: {}, pagination: nil, can: {}, auth: {} }
    )

    expect { c.to_inertia }.to raise_error(ArgumentError, /extra=\[:auth\]/)
  end

  it "builds capabilities from the declared policy methods" do
    props_class.capability("billing:invoice:create", :create?)
    props_class.capability("billing:invoice:export", :export?)
    c = props_class.new(
      context: context,
      envelope: { data: {}, meta: {}, query: {}, pagination: nil, can: {} }
    )

    capabilities = c.capabilities("billing:invoice:create", "billing:invoice:export")

    expect(capabilities).to eq(
      "invoice.create" => { allowed: true, reason: nil },
      "invoice.export" => { allowed: false, reason: "forbidden" }
    )
  end

  it "raises on an undeclared capability" do
    c = props_class.new(
      context: context,
      envelope: { data: {}, meta: {}, query: {}, pagination: nil, can: {} }
    )

    expect { c.capabilities("billing:invoice:create") }
      .to raise_error(ArgumentError, /declares no capability/)
  end
end
