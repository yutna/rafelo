require "rails_helper"

RSpec.describe Rafelo::RedactStorageRedirects do
  let(:subscriber) { ActionController::LogSubscriber.new }

  it "does not log a signed Active Storage redirect" do
    event = Struct.new(:payload).new({ location: "https://app.test/rails/active_storage/blobs/redirect/abc?token=secret" })

    expect(subscriber).not_to receive(:info)
    subscriber.redirect_to(event)
  end

  it "still logs an ordinary redirect" do
    event = Struct.new(:payload).new({ location: "https://app.test/en" })

    expect(subscriber).to receive(:info).at_least(:once)
    subscriber.redirect_to(event)
  end
end
