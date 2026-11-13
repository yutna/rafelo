require "rails_helper"

RSpec.describe "Write action flow", type: :request do
  def page_body(response)
    JSON.parse(response.body[/<script[^>]*data-page="app"[^>]*>(.*?)<\/script>/m, 1])
  end

  it "redirects with a one-shot flash on success and never as a prop" do
    post "/en/dummy/widgets", params: { name: "ada" }

    expect(response).to have_http_status(:see_other)
    expect(response.location).to end_with("/en/dummy/widgets")

    get response.location
    page = page_body(response)
    expect(page.dig("flash", "notice")).to eq("Widget created.")
    expect(page.dig("props", "flash")).to be_nil

    get "/en/dummy/widgets"
    expect(page_body(response)["flash"]).to be_nil
  end

  it "redirects with translated shape errors" do
    post "/en/dummy/widgets", params: { name: "" }

    expect(response).to have_http_status(:see_other)
    get response.location
    expect(page_body(response).dig("props", "errors", "name")).to eq("can't be blank")
  end

  it "maps known and unknown upstream fields to field and base errors" do
    post "/en/dummy/widgets/validation"

    expect(response).to have_http_status(:see_other)
    get response.location
    errors = page_body(response).dig("props", "errors")
    expect(errors["name"]).to eq("is too long")
    expect(errors["base"]).to eq("has already been taken")
  end

  it "redirects a conflict to the edit page with a base message" do
    post "/en/dummy/widgets/conflict"

    expect(response).to have_http_status(:see_other)
    get response.location
    expect(page_body(response).dig("props", "errors", "base")).to eq("The record changed since you opened it.")
  end

  it "renders the shared error page for an unexpected failure" do
    post "/en/dummy/widgets/boom"

    expect(response).to have_http_status(:internal_server_error)
  end
end
