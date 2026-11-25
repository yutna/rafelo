require "rails_helper"

RSpec.describe Rafelo::Core::ErrorPagesController, type: :controller do
  around do |example|
    previous = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
    example.run
  ensure
    ActionController::Base.allow_forgery_protection = previous
  end

  before do
    routes.draw { post "error_page" => "rafelo/core/error_pages#show" }
  end

  after { Rails.application.reload_routes! }

  def error_env(status:, code:)
    request.env["rafelo.exceptions.status"] = status
    request.env["rafelo.exceptions.code"] = code
    request.env["rafelo.exceptions.locale"] = "en"
  end

  it "keeps the original status for a write without a CSRF token" do
    error_env(status: 500, code: "unexpected")

    post :show

    expect(response).to have_http_status(:internal_server_error)
  end

  it "renders a forged write as request.csrf_failed" do
    error_env(status: 422, code: "request.csrf_failed")

    post :show

    expect(response).to have_http_status(422)
  end
end
