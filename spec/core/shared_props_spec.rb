require "rails_helper"

RSpec.describe Rafelo::Core::SharedProps do
  after { Rafelo::Core::Modules.reset! }

  let(:context) do
    Rafelo::Core::PageContext.new(
      viewer: nil,
      permissions: nil,
      flags: {},
      locale: :th,
      request_id: "request-1",
      urls: Rafelo::Core::Urls.new(locale: :th, router: Class.new.new)
    )
  end
  let(:props) { described_class.new(context: context, request_path: "/th") }

  it "builds auth, app, nav and errors" do
    expect(props.to_h).to eq(
      auth: { viewer: nil },
      app: {
        name: "Rafelo",
        locale: "th",
        locales: %w[en th],
        localeHrefs: [ { locale: "en", href: "/en" }, { locale: "th", href: "/th" } ],
        timeZone: Time.zone.name
      },
      nav: []
    )
  end

  it "builds trace from the response ids" do
    Rafelo::Core::Current.trace_id = "trace-1"

    expect(props.trace).to eq(requestId: "request-1", traceId: "trace-1")
  ensure
    Rafelo::Core::Current.trace_id = nil
  end

  it "keeps shared props inside their byte budget" do
    expect(props.to_h.to_json.bytesize).to be <= 8_192
  end
end
