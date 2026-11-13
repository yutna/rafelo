# frozen_string_literal: true

class SessionsController < ApplicationController
  skip_before_action :load_session, only: %i[new create]
  skip_before_action :refresh_stale_grants, only: %i[new create]
  skip_before_action :require_viewer, only: %i[new create]
  before_action :skip_authorization

  throttle to: 10, within: 1.minute, only: :create, name: "sign_in/ip"
  throttle to: 30, within: 1.minute, only: :destroy, name: "sign_out/ip"
  throttle to: 10, within: 1.minute, only: :destroy_all, name: "sign_out_everywhere/ip"

  def new
    render_page "sessions/new", props: SessionsNewProps.new(context: page_context, csrf_token: form_authenticity_token)
  end

  def create
    result = Rafelo::Core::AuthGateway.new(
      budget: Rafelo::Core::CallBudget.new(api: 3),
      request_id: request.request_id,
      trace_id: request.request_id
    ).sign_in(email: params[:email], password: params[:password])
    Rafelo::Core::Session.find_by_token(cookies[session_cookie_name])&.destroy if cookies[session_cookie_name]
    reset_session
    session, token = Rafelo::Core::Session.start(
      viewer: result.viewer,
      access_token: result.access_token,
      refresh_token: result.refresh_token,
      access_expires_at: result.access_expires_at,
      locale: I18n.locale,
      grants: result.grants
    )
    cookies[session_cookie_name] = {
      value: token,
      httponly: true,
      same_site: :lax,
      secure: !Rails.env.local?,
      expires: session.expires_at
    }
    redirect_to "/#{I18n.locale}", status: :see_other
  rescue Rafelo::Core::ApplicationError => error
    render_page "sessions/new",
                props: SessionsNewProps.new(context: page_context, csrf_token: form_authenticity_token, error: error.message),
                status: error.status
  end

  def destroy
    token = cookies[session_cookie_name]
    Rafelo::Core::Session.find_by_token(token)&.destroy if token
    reset_session
    cookies.delete(session_cookie_name, secure: !Rails.env.local?, path: "/")
    redirect_to "/#{I18n.locale}/sign_in", status: :see_other, inertia: { clear_history: true }
  end

  def destroy_all
    Rafelo::Core::Session.revoke_all!(Rafelo::Core::Current.viewer.id) if Rafelo::Core::Current.viewer
    clear_session!
    redirect_to "/#{I18n.locale}/sign_in", status: :see_other, inertia: { clear_history: true }
  end
end
