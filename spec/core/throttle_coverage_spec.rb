require "rails_helper"

RSpec.describe "Throttle coverage" do
  ALLOWED_WRITE_CONTROLLERS = {
    %r{\Arails/} => "Rails internal development routes; not part of the app surface",
    %r{\Aactive_storage/} => "Active Storage framework endpoints",
    %r{\Aaction_mailbox/} => "Action Mailbox framework endpoints",
    %r{\Aaction_text/} => "Action Text framework endpoints"
  }.freeze

  def routes_for(route_set)
    route_set.routes.flat_map do |route|
      engine = route.app.app if route.app.respond_to?(:app) && route.app.app.respond_to?(:routes)
      engine ? routes_for(engine.routes) : [ route ]
    end
  end

  it "throttles every app or engine write action that is not allow-listed" do
    checked = []
    routes_for(Rails.application.routes).each do |route|
      controller = route.defaults[:controller]
      action = route.defaults[:action]
      next if controller.blank? || action.blank?
      next if %w[GET HEAD OPTIONS].include?(route.verb)

      reason = ALLOWED_WRITE_CONTROLLERS.find { |pattern, _| pattern.match?(controller) }
      next if reason

      klass = "#{controller.camelize}Controller".constantize
      expect(klass.throttle_limits[action.to_sym]).to be_present,
        "#{controller}##{action} is a write action with no throttle and no allow-list reason"
      checked << "#{controller}##{action}"
    end

    expect(checked).to include("sessions#create", "sessions#destroy", "sessions#destroy_all")
  end
end
