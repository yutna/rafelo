require "rails_helper"

RSpec.describe Rafelo::Core::AuthGateway do
  let(:gateway) do
    described_class.new(
      budget: Rafelo::Core::CallBudget.new(api: 3, deadline: Rafelo::Core::RequestDeadline.new(30)),
      request_id: "request-1",
      trace_id: "trace-1"
    )
  end

  it "maps malformed sign-in JSON to the unexpected catalog error" do
    stub_request(:post, "http://localhost:4000/auth/sign_in")
      .to_return(status: 200, body: "not-json")

    expect { gateway.sign_in(email: "ada@example.test", password: "secret") }
      .to raise_error(Rafelo::Core::ApplicationError) { |error| expect(error.code).to eq("unexpected") }
  end

  it "passes the budget deadline to the refresh client" do
    budget = Rafelo::Core::CallBudget.new(api: 3, deadline: Rafelo::Core::RequestDeadline.new(30))
    deadline_gateway = described_class.new(budget: budget, request_id: "request-1", trace_id: "trace-1")
    stub_request(:post, "http://localhost:4000/auth/refresh")
      .to_return(status: 200, body: "not-json")
    allow(Rafelo::Core::UpstreamClient).to receive(:for).and_call_original

    expect { deadline_gateway.refresh(refresh_token: "old-refresh") }
      .to raise_error(Rafelo::Core::ApplicationError)

    expect(Rafelo::Core::UpstreamClient).to have_received(:for)
      .with(:api, hash_including(deadline: budget.deadline))
  end

  it "maps malformed refresh JSON to the unexpected catalog error" do
    stub_request(:post, "http://localhost:4000/auth/refresh")
      .to_return(status: 200, body: "not-json")

    expect { gateway.refresh(refresh_token: "old-refresh") }
      .to raise_error(Rafelo::Core::ApplicationError) { |error| expect(error.code).to eq("unexpected") }
  end
end
