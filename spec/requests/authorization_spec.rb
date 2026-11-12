require "rails_helper"

class AuthorizationProbeController < ApplicationController
  def missing
    render plain: "missing authorization"
  end

  def authorized
    authorize :home, :show?
    render plain: "authorized #{params[:foo_bar]}"
  end

  def denied
    authorize :home, :missing?
    render plain: "never"
  end
end

RSpec.describe "Authorization", type: :request do
  before do
    Rails.application.routes.draw do
      scope ":locale", locale: /[a-z]{2}/ do
        get "/probe/missing", to: "authorization_probe#missing"
        get "/probe/authorized", to: "authorization_probe#authorized"
        get "/probe/denied", to: "authorization_probe#denied"
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
    expect(response.headers["Cache-Control"]).to include("no-store")
  end

  it "renders the shared error page for an Inertia denial" do
    get "/th/probe/denied", headers: { "X-Inertia" => "true", "X-Inertia-Version" => Rafelo::Core::AssetVersion.call }

    expect(response).to have_http_status(:forbidden)
    page = JSON.parse(response.body)
    expect(page["component"]).to eq("errors/show")
    expect(page.dig("props", "data", "code")).to eq("auth.forbidden")
    expect(page.dig("props", "data", "message")).to include("ไม่มีสิทธิ์")
    expect(page.dig("props", "trace")).to include("requestId", "traceId")
  end

  it "renders the shared error page for an HTML denial" do
    get "/th/probe/denied"

    expect(response).to have_http_status(:forbidden)
    expect(response.body).to include('"component":"errors/show"')
    expect(response.body).to include("ไม่มีสิทธิ์")
    expect(response.headers["Cache-Control"]).to include("no-store")
  end

  it "renders the Thai error message and both ids when authorization is denied" do
    get "/th/probe/missing"

    expect(response).to have_http_status(:forbidden)
    body = response.parsed_body.fetch("error")
    expect(body["code"]).to eq("auth.forbidden")
    expect(body["message"]).to include("ไม่มีสิทธิ์")
    expect(body["requestId"]).to be_present
    expect(body["traceId"]).to be_present
    expect(response.headers["Cache-Control"]).to include("no-store")
  end

  it "allows an action that authorizes through its policy" do
    get "/en/probe/authorized?fooBar=probe"

    expect(response).to have_http_status(:ok)
    expect(response.body).to eq("authorized probe")
    expect(response.headers["Cache-Control"]).to include("no-store")
  end
end
