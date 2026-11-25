require "rails_helper"

RSpec.describe Rafelo::Core::PageContextFactory do
  let(:urls) do
    Rafelo::Core::Urls.new(
      locale: :en,
      router: double("router")
    )
  end

  def build(session:)
    described_class.build(
      session: session,
      trace_id: "trace-1",
      flags: { search: true },
      locale: :en,
      request_id: "request-1",
      urls: urls
    )
  end

  it "takes the viewer, permissions, and session id from the one session" do
    viewer = Rafelo::Core::Viewer.new(id: 7, name: "Ada")
    session = double(
      viewer: viewer,
      permission_set: Rafelo::Core::PermissionSet.new([ "example_orders:order:read" ]),
      id: 42
    )

    context = build(session: session)

    expect(context.viewer).to be(viewer)
    expect(context.permissions.allows?("example_orders:order:read")).to be(true)
    expect(context.session_id).to eq(42)
    expect(context.trace_id).to eq("trace-1")
  end

  it "has no viewer or session id and an empty permission set without a session" do
    context = build(session: nil)

    expect(context.viewer).to be_nil
    expect(context.session_id).to be_nil
    expect(context.permissions.allows?("example_orders:order:read")).to be(false)
    expect(context.permissions.reads_any?([ "example_orders" ])).to be(false)
  end
end
