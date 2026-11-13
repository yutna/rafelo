require "rails_helper"

RSpec.describe "Client error reports", type: :request do
  it "accepts a report with a CSRF token" do
    get "/en/sign_in"
    token = response.body[/name="csrf-token" content="([^"]+)"/, 1]

    post "/core/client_errors", params: { message: "boom" }, headers: { "X-CSRF-Token" => token }

    expect(response).to have_http_status(:no_content)
  end
end
