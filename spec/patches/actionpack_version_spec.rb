require "rails_helper"

RSpec.describe "Action Pack patch version" do
  it "records the version the redirect log patch was written for" do
    expect(Gem.loaded_specs.fetch("actionpack").version.to_s).to eq("8.1.4.1")
  end
end
