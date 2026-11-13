require "rails_helper"

RSpec.describe "Unsupported browsers", type: :request do
  OLD_AGENT = "Mozilla/5.0 (Windows NT 6.1; Trident/7.0; rv:11.0) like Gecko"

  it "renders a translated, script-free 406 page under Thai" do
    get "/th", headers: { "User-Agent" => OLD_AGENT }

    expect(response).to have_http_status(:not_acceptable)
    expect(response.body).to include('lang="th"')
    expect(response.body).to include("เบราว์เซอร์ของคุณไม่รองรับ")
    expect(response.body).not_to include("<script")
    expect(response.body).to match(/<style nonce="[^"]+">/)
    expect(response.headers["Cache-Control"]).to include("no-store")
  end

  it "lets a core endpoint through the browser check" do
    get "/core/ready", headers: { "User-Agent" => OLD_AGENT }

    expect(response).not_to have_http_status(:not_acceptable)
  end
end
