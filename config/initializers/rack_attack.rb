# frozen_string_literal: true

Rack::Attack.cache.store = Rails.cache

Rack::Attack.throttle("sign_in/ip", limit: 10, period: 60) do |request|
  request.ip if request.post? && request.path.end_with?("/sign_in")
end

Rack::Attack.throttle("core_reports/ip", limit: 30, period: 60) do |request|
  request.ip if request.path.start_with?("/core/")
end
