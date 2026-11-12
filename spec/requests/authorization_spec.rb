require "rails_helper"

class AuthorizationProbeController < ApplicationController
  def missing
    render plain: "missing authorization"
  end

  def authorized
    authorize :home, :show?
    render plain: "authorized"
  end
end

RSpec.describe "Authorization", type: :request do
  before do
    Rails.application.routes.draw do
      scope ":locale", locale: /[a-z]{2}/ do
        get "/probe/missing", to: "authorization_probe#missing"
        get "/probe/authorized", to: "authorization_probe#authorized"
      end
    end
  end

  after do
    Rails.application.reload_routes!
  end

  it "returns 403 auth.forbidden when an action forgets authorize" do
    get "/en/probe/missing"

    expect(response).to have_http_status(:forbidden)
    expect(response.parsed_body.dig("error", "code")).to eq("auth.forbidden")
  end

  it "allows an action that authorizes through its policy" do
    get "/en/probe/authorized"

    expect(response).to have_http_status(:ok)
    expect(response.body).to eq("authorized")
    expect(response.headers["Cache-Control"]).to include("no-store")
  end
end
