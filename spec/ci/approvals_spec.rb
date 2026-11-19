# frozen_string_literal: true

require "rails_helper"
require Rails.root.join("script/ci/approvals").to_s

RSpec.describe Approvals do
  def review(login, state)
    { "user" => { "login" => login }, "state" => state }
  end

  it "reads every review page from the public API fallback" do
    allow(Open3).to receive(:capture2).and_raise(Errno::ENOENT)
    first = "https://api.github.com/repos/acme/app/pulls/7/reviews?per_page=100&page=1"
    second = "https://api.github.com/repos/acme/app/pulls/7/reviews?per_page=100&page=2"
    stub_request(:get, first)
      .to_return(status: 200, body: JSON.generate([ review("owner", "APPROVED") ]),
                 headers: { "Content-Type" => "application/json", "Link" => "<#{second}>; rel=\"next\"" })
    stub_request(:get, second)
      .to_return(status: 200, body: JSON.generate([ review("owner", "CHANGES_REQUESTED") ]),
                 headers: { "Content-Type" => "application/json" })

    reviews = described_class.reviews(pr: 7, repository: "acme/app")

    expect(reviews.map { |entry| entry["state"] }).to eq(%w[APPROVED CHANGES_REQUESTED])
  end
end
