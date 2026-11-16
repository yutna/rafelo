require "rails_helper"

RSpec.describe Rafelo::Core::CallBudget do
  it "takes page and refresh limits from config/budgets.yml" do
    budget = described_class.default

    budget.consume!(:api)
    budget.consume!(:api, kind: :session_refresh)

    expect(budget.count(:api)).to eq(1)
    expect(budget.count(:api, kind: :session_refresh)).to eq(1)
    expect(budget.count(:api)).to eq(1), "a refresh must not consume a page slot"
  end

  it "gives every named upstream its configured budget, never 0" do
    budget = described_class.new(api: 3, other: 2)

    expect { budget.consume!(:other) }.not_to raise_error
    expect(budget.count(:other)).to eq(1)
  end

  it "raises for an upstream with no page budget instead of answering 429" do
    budget = described_class.new(api: 3)

    expect { budget.consume!(:other) }.to raise_error(ArgumentError, /no call budget for upstream other/)
  end

  it "uses the job limit for a viewer job" do
    budget = described_class.job(deadline: Rafelo::Core::RequestDeadline.new(5))

    10.times { budget.consume!(:api) }
    expect { budget.consume!(:api) }.to raise_error(Rafelo::Core::ApplicationError) { |error| expect(error.code).to eq("request.throttled") }
  end
end
