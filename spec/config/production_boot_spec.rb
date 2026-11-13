require "rails_helper"
require "open3"

RSpec.describe "Production dummy boot" do
  def environment
    File.readlines(Rails.root.join(".env.ci.production"), chomp: true)
      .reject { |line| line.empty? || line.start_with?("#") }
      .to_h { |line| line.split("=", 2) }
      .merge("RAILS_ENV" => "production")
      .reject { |key, _| key == "RAILS_MASTER_KEY" }
  end

  it "refuses the dummy flag outside the two build tasks" do
    output, status = Open3.capture2e(
      environment.merge("SECRET_KEY_BASE_DUMMY" => "1"),
      "bin/rails", "runner", "puts :ok", chdir: Rails.root.to_s
    )

    expect(status).not_to be_success
    expect(output).to include("only for assets:precompile and ci:production_routes")
  end

  it "refuses a production boot without RAILS_MASTER_KEY" do
    output, status = Open3.capture2e(
      environment,
      "bin/rails", "runner", "puts :ok", chdir: Rails.root.to_s
    )

    expect(status).not_to be_success
    expect(output).to include("Missing encryption key")
  end
end
