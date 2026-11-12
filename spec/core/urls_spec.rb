require "rails_helper"

RSpec.describe Rafelo::Core::Urls do
  proxy = Class.new do
    def new_invoice(locale:, id:)
      "/#{locale}/billing/invoices/new?id=#{id}"
    end
  end.new

  let(:proxy) { proxy }
  let(:router) do
    Class.new do
      define_method(:billing) { proxy }
    end.new
  end
  let(:urls) { described_class.new(locale: :th, router: router) }

  it "builds a locale-prefixed path through the mounted engine proxy and records it" do
    expect(urls.route(:billing, :new_invoice, id: 7)).to eq("/th/billing/invoices/new?id=7")
    expect(urls.built).to eq([ "/th/billing/invoices/new?id=7" ])
  end

  it "raises on an unknown engine or route name" do
    expect { urls.route(:billing, :missing) }.to raise_error(ArgumentError, /billing\.missing/)
    expect { urls.route(:missing, :new_invoice) }.to raise_error(ArgumentError, /missing\.new_invoice/)
  end
end
