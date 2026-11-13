require "rails_helper"

RSpec.describe "Exports", type: :request do
  let(:viewer) { Struct.new(:id, :name).new(7, "Ada") }

  def session_cookie(viewer_id = 7)
    viewer = Struct.new(:id, :name).new(viewer_id, "Ada")
    _, token = Rafelo::Core::Session.start(
      viewer: viewer, access_token: "a", refresh_token: "r", access_expires_at: 5.minutes.from_now
    )
    "session_token=#{token}"
  end

  def export_for(viewer_id, attached: true)
    export = Rafelo::Core::Export.create!(
      viewer_id: viewer_id.to_s, status: "ready", filename: "report.csv", expires_at: 1.hour.from_now
    )
    export.file.attach(io: StringIO.new("a,b\n"), filename: "report.csv", content_type: "text/csv") if attached
    export
  end

  it "streams the owner's export without a signed URL" do
    export = export_for(7)
    get "/en/dummy/export/#{export.id}", headers: { "Cookie" => session_cookie(7) }

    expect(response).to have_http_status(:ok)
    expect(response.body).to eq("a,b\n")
    expect(response.headers["Content-Disposition"]).to include("attachment")
    expect(response.headers["Content-Disposition"]).to include("report.csv")
    expect(response.location).to be_nil
  end

  it "throttles export downloads" do
    export = export_for(7)
    cookie = session_cookie(7)

    31.times { get "/en/dummy/export/#{export.id}", headers: { "Cookie" => cookie } }

    expect(response).to have_http_status(:too_many_requests)
  end

  it "denies another viewer's export and hides an unattached file" do
    export = export_for(7)
    get "/en/dummy/export/#{export.id}", headers: { "Cookie" => session_cookie(8) }
    expect(response).to have_http_status(:forbidden)

    unattached = export_for(8, attached: false)
    get "/en/dummy/export/#{unattached.id}", headers: { "Cookie" => session_cookie(8) }
    expect(response).to have_http_status(:not_found)
  end
end
