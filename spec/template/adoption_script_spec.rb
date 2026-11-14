# frozen_string_literal: true

require "rails_helper"

RSpec.describe "script/ci/adoption" do
  let(:script) { File.read(File.expand_path("../../script/ci/adoption", __dir__)) }

  it "commits the N-1 update with an explicit identity" do
    expect(script).to include('user.name="Rafelo CI"')
    expect(script).to include('user.email="ci@rafelo.invalid"')
    expect(script).to include("-c commit.gpgsign=false")
  end

  it "fails on a missing base tag instead of skipping the N-1 proof" do
    expect(script).to include('rev-parse -q --verify "refs/tags/$base_tag"')
    expect(script.index("rev-parse -q --verify")).to be < script.index("predates the template payload")
  end
end
