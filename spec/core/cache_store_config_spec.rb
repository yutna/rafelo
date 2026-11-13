require "rails_helper"

RSpec.describe "Throttle cache store" do
  it "uses a real store whose increment returns an integer in test" do
    expect(Rails.cache).not_to be_a(ActiveSupport::Cache::NullStore)
    expect(Rails.cache.increment("throttle-spec", 1)).to be_a(Integer)
  end

  it "uses Solid Cache in production" do
    expect(Rails.root.join("config/environments/production.rb").read).to include("config.cache_store = :solid_cache_store")
  end
end
