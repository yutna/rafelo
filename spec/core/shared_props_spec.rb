require "rails_helper"

RSpec.describe Rafelo::Core::SharedProps do
  before { allow(Rafelo::Core::Modules).to receive(:all).and_return([]) }

  let(:context) do
    Rafelo::Core::PageContext.new(
      viewer: nil,
      permissions: nil,
      flags: {},
      locale: :th,
      request_id: "request-1",
      trace_id: "trace-1",
      session_id: nil,
      urls: Rafelo::Core::Urls.new(locale: :th, router: Class.new.new)
    )
  end
  let(:props) { described_class.new(context: context, request_path: "/th") }

  it "builds auth, app, nav and errors" do
    expect(props.to_h).to eq(
      auth: { viewer: nil },
      app: {
        name: Rails.application.class.module_parent_name,
        locale: "th",
        locales: %w[en th],
        localeHrefs: [ { locale: "en", href: "/en" }, { locale: "th", href: "/th" } ],
        signInHref: "/th/sign_in",
        timeZone: Time.zone.name
      },
      nav: []
    )
  end

  it "builds trace from the context ids" do
    expect(props.trace).to eq(requestId: "request-1", traceId: "trace-1")
  end

  it "keeps shared props inside their byte budget" do
    expect(props.to_h.to_json.bytesize).to be <= 8_192
  end

  describe "navigation" do
    let(:entry) do
      double(
        key: :example_orders,
        permission_prefixes: [ "example_orders" ],
        flag: nil,
        root_route?: true,
        nav: { label_key: "example_orders.nav.title", icon: "receipt" },
        path: "/example_orders"
      )
    end

    def context_with(grants)
      Rafelo::Core::PageContextFactory.build(
        viewer: Struct.new(:id, :name).new(7, "Ada"),
        permissions: Rafelo::Core::PermissionSet.new(grants),
        flags: {},
        locale: :en,
        request_id: "request-1",
        trace_id: "trace-1",
        urls: Rafelo::Core::Urls.new(
          locale: :en,
          router: double(example_orders: double(root_path: "/en/example_orders"))
        )
      )
    end

    before { allow(Rafelo::Core::Modules).to receive(:all).and_return([ entry ]) }

    it "keeps a module only when the viewer may read one of its prefixes" do
      expect(described_class.new(context: context_with([]), request_path: "/en").to_h.fetch(:nav)).to be_empty

      nav = described_class.new(
        context: context_with([ "example_orders:order:read" ]), request_path: "/en"
      ).to_h.fetch(:nav)

      expect(nav.map { |item| item[:key] }).to eq([ "example_orders" ])
      expect(nav.first[:path]).to eq("/en/example_orders")
      expect(nav.first[:current]).to be(false)
    end

    it "marks the module that served the request current" do
      nav = described_class.new(
        context: context_with([ "example_orders:order:read" ]),
        request_path: "/en/example_orders/orders"
      ).to_h.fetch(:nav)

      expect(nav.first[:current]).to be(true)
    end

    it "drops a module the app did not mount" do
      allow(entry).to receive(:root_route?).and_return(true)
      context = Rafelo::Core::PageContext.new(
        viewer: Struct.new(:id, :name).new(7, "Ada"),
        permissions: Rafelo::Core::PermissionSet.new([ "*" ]),
        flags: {},
        locale: :en,
        request_id: "request-1",
        trace_id: "trace-1",
        session_id: nil,
        urls: Rafelo::Core::Urls.new(locale: :en, router: double)
      )

      expect(described_class.new(context: context, request_path: "/en").to_h.fetch(:nav)).to be_empty
    end

    it "drops a module whose engine has no root route" do
      allow(entry).to receive(:root_route?).and_return(false)

      expect(described_class.new(context: context_with([ "*" ]), request_path: "/en").to_h.fetch(:nav)).to be_empty
    end
  end
end
