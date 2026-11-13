# frozen_string_literal: true

module AuthenticationHelpers
  # A real session row and cookie for request specs that exercise pages behind
  # require_viewer (BE-24). Session flow specs still sign in through the public
  # endpoints themselves.
  def sign_in_cookie(viewer_id: 7, name: "Ada", grants: [])
    viewer = Struct.new(:id, :name).new(viewer_id, name)
    _, token = Rafelo::Core::Session.start(
      viewer: viewer,
      access_token: "access",
      refresh_token: "refresh",
      access_expires_at: 5.minutes.from_now,
      grants: grants
    )
    "session_token=#{token}"
  end

  def auth_headers(**options)
    return @auth_headers ||= { "Cookie" => sign_in_cookie } if options.empty?

    { "Cookie" => sign_in_cookie(**options) }
  end

  # Keep both cookies when following a redirect: the BFF session cookie is
  # explicit, while Rails' own session carries Inertia errors and flash.
  def follow_redirect(cookie)
    rails = Array(response.headers["Set-Cookie"]).filter_map do |value|
      value.split(";").first if value.start_with?("rafelo_session=")
    end.first
    get response.location, headers: { "Cookie" => [ cookie, rails ].compact.join("; ") }
  end
end

RSpec.configure do |config|
  config.include AuthenticationHelpers
end
