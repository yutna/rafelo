# frozen_string_literal: true

class SessionsController < ApplicationController
  skip_before_action :load_session, only: %i[new create]
  before_action :skip_authorization

  def new
    render_page "sessions/new", props: SessionsNewProps.new(context: page_context)
  end

  def create
    result = Rafelo::Core::AuthGateway.new(
      budget: Rafelo::Core::CallBudget.new(api: 3),
      request_id: request.request_id,
      trace_id: request.request_id
    ).sign_in(email: params[:email], password: params[:password])
    session, token = Rafelo::Core::Session.start(
      viewer: result.viewer,
      access_token: result.access_token,
      refresh_token: result.refresh_token,
      access_expires_at: result.access_expires_at,
      locale: I18n.locale,
      grants: result.grants
    )
    cookies[:session_token] = {
      value: token,
      httponly: true,
      same_site: :lax,
      secure: !Rails.env.local?,
      expires: session.expires_at
    }
    redirect_to "/#{I18n.locale}", status: :see_other
  rescue Rafelo::Core::ApplicationError => error
    render_page "sessions/new",
                props: SessionsNewProps.new(context: page_context, error: error.message),
                status: error.status
  end

  def destroy
    token = cookies[:session_token]
    Rafelo::Core::Session.find_by_token(token)&.destroy if token
    cookies.delete(:session_token)
    redirect_to "/#{I18n.locale}/sign_in", status: :see_other
  end
end
