require "rails_helper"
require "rake"

RSpec.describe "rafelo:restore:prepare" do
  let(:task) { Rake::Task["rafelo:restore:prepare"] }

  before do
    Rails.application.load_tasks unless Rake::Task.task_defined?("rafelo:restore:prepare")
    task.reenable
  end

  after do
    task.reenable
    ENV.delete("RAFELO_DATABASE_ROLE")
    ENV.delete("RAFELO_RESTORE_CONFIRMED")
  end

  it "refuses without the migration role" do
    ENV["RAFELO_RESTORE_CONFIRMED"] = "1"

    expect { task.invoke }.to raise_error(SystemExit)
  end

  it "refuses without the explicit confirmation" do
    ENV["RAFELO_DATABASE_ROLE"] = "migration"

    expect { task.invoke }.to raise_error(SystemExit)
  end

  it "empties sessions when both guards are present" do
    Rafelo::Core::Session.create!(
      token_digest: "drill-session",
      viewer_id: "7",
      expires_at: 1.hour.from_now
    )
    ENV["RAFELO_DATABASE_ROLE"] = "migration"
    ENV["RAFELO_RESTORE_CONFIRMED"] = "1"

    expect { task.invoke }.not_to raise_error

    expect(Rafelo::Core::Session.count).to eq(0)
  end
end
