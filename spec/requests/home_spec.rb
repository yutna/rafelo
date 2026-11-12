require "rails_helper"

RSpec.describe "Home page", type: :request do
  it "renders the Inertia root with the home component" do
    get "/en"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('id="app"')
    expect(response.body).to include('"component":"home/index"')
    expect(response.body).to include('"message":"Rafelo"')
  end
end
