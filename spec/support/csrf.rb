# frozen_string_literal: true

RSpec.shared_context "csrf" do
  around do |example|
    previous = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
    example.run
  ensure
    ActionController::Base.allow_forgery_protection = previous
  end

  def csrf_token_from_response
    cookie = Array(response.headers["Set-Cookie"]).flat_map { |header| header.split("\n") }
      .find { |value| value.start_with?("XSRF-TOKEN=") }
    return unless cookie

    CGI.unescape(cookie.split(";").first.split("=", 2).last)
  end
end

RSpec.configure do |config|
  config.include_context "csrf", :csrf
end
