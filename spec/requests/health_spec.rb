require "rails_helper"

RSpec.describe "Health endpoints", type: :request do
  around do |example|
    previous = Rails.application.env_config["action_dispatch.show_exceptions"]
    previous_detailed = Rails.application.env_config["action_dispatch.show_detailed_exceptions"]
    Rails.application.env_config["action_dispatch.show_exceptions"] = :all
    Rails.application.env_config["action_dispatch.show_detailed_exceptions"] = false
    example.run
  ensure
    Rails.application.env_config["action_dispatch.show_exceptions"] = previous
    Rails.application.env_config["action_dispatch.show_detailed_exceptions"] = previous_detailed
  end

  it "answers liveness without touching a dependency or an upstream" do
    calls = []
    subscriber = ActiveSupport::Notifications.subscribe("upstream.call") { |*, payload| calls << payload }
    sql = []
    sql_subscriber = ActiveSupport::Notifications.subscribe("sql.active_record") { |*, payload| sql << payload }

    get "/up"

    expect(response).to have_http_status(:ok)
    expect(calls).to be_empty
    expect(sql).to be_empty
  ensure
    ActiveSupport::Notifications.unsubscribe(subscriber) if subscriber
    ActiveSupport::Notifications.unsubscribe(sql_subscriber) if sql_subscriber
  end

  it "answers readiness with a trivial PostgreSQL query and no upstream" do
    calls = []
    subscriber = ActiveSupport::Notifications.subscribe("upstream.call") { |*, payload| calls << payload }

    get "/core/ready"

    expect(response).to have_http_status(:ok)
    expect(calls).to be_empty
  ensure
    ActiveSupport::Notifications.unsubscribe(subscriber) if subscriber
  end

  it "fails readiness when PostgreSQL is unavailable" do
    allow(ActiveRecord::Base).to receive(:connection).and_raise(ActiveRecord::ConnectionNotEstablished.new("down"))

    get "/core/ready"

    expect(response).to have_http_status(:internal_server_error)
  end
end
