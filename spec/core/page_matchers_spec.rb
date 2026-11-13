require "rails_helper"

RSpec.describe "Page matchers", type: :request do
  FakeRequest = Struct.new(:env)
  FakeResponse = Struct.new(:body, :request)

  def fake_response(page, env = {})
    FakeResponse.new(JSON.generate(page), FakeRequest.new(env))
  end

  describe "match_page_schema" do
    it "passes for the rendered component and page key" do
      get "/en", headers: auth_headers
      page = PageMatchers.page_of(response)

      expect(fake_response(page, response.request.env)).to match_page_schema("home/index")
    end

    it "fails when the component does not match the page key" do
      get "/en", headers: auth_headers
      page = PageMatchers.page_of(response)

      expect(fake_response(page, response.request.env)).not_to match_page_schema("sessions/new")
    end
  end

  describe "have_resolvable_hrefs" do
    let(:page) do
      {
        "component" => "home/index",
        "props" => {
          "data" => { "href" => "/en?page=2" },
          "nav" => [ { "path" => "/en" } ]
        }
      }
    end

    it "uses the paths recorded by Urls#built" do
      expect(fake_response(page, { "rafelo.urls_built" => [ "/en" ] })).to have_resolvable_hrefs("home/index")
    end

    it "fails when an href was not built" do
      page["props"]["data"]["href"] = "/not-built"

      expect(fake_response(page, { "rafelo.urls_built" => [ "/en" ] })).not_to have_resolvable_hrefs("home/index")
    end

    it "fails without a built-URL capture" do
      expect(fake_response(page)).not_to have_resolvable_hrefs("home/index")
    end
  end

  describe "be_within_props_budget" do
    def paginated_page(per_page:, items:)
      {
        "component" => "home/index",
        "props" => {
          "data" => { "items" => items },
          "meta" => {},
          "query" => {},
          "pagination" => { "perPage" => per_page },
          "can" => {}
        }
      }
    end

    it "passes at the ListQuery maximum page size" do
      maximum = Rafelo::Core::ListQuery.max_per_page
      page = paginated_page(per_page: maximum, items: Array.new(maximum) { {} })

      expect(fake_response(page)).to be_within_props_budget("home/index")
    end

    it "fails when perPage is below the maximum" do
      page = paginated_page(per_page: 25, items: Array.new(25) { {} })

      expect(fake_response(page)).not_to be_within_props_budget("home/index")
    end

    it "fails when the list is shorter than perPage" do
      maximum = Rafelo::Core::ListQuery.max_per_page
      page = paginated_page(per_page: maximum, items: Array.new(maximum - 1) { {} })

      expect(fake_response(page)).not_to be_within_props_budget("home/index")
    end

    it "exempts a page declared paginated: false" do
      page = paginated_page(per_page: 25, items: [])
      page["props"]["pagination"] = nil

      expect(fake_response(page)).to be_within_props_budget("home/index")
    end
  end

  describe "match_policy_capabilities" do
    let(:policy_class) do
      Class.new(Rafelo::Core::BasePolicy) do
        def show? = true
        def create? = false
      end
    end

    let(:props_class) do
      policy = policy_class
      Class.new(Rafelo::Core::PageProps) do
        policy_class policy
        capability "demo:widget:show", :show?
        capability "demo:widget:create", :create?

        def envelope
          {
            data: {},
            meta: {},
            query: {},
            pagination: nil,
            can: capabilities("demo:widget:show", "demo:widget:create")
          }
        end
      end
    end

    let(:context) do
      Rafelo::Core::PageContext.new(
        viewer: Rafelo::Core::Viewer.new(id: "spec-1", name: "Spec"),
        permissions: Rafelo::Core::PermissionSet.new([]),
        flags: {},
        locale: :en,
        request_id: "request-1",
        urls: Rafelo::Core::Urls.new(locale: :en)
      )
    end

    let(:props) { props_class.new(context: context) }
    let(:page) { JSON.parse({ "component" => "home/index", "props" => props.to_inertia }.to_json) }
    let(:response) { fake_response(page, { "rafelo.page_props" => props }) }

    it "compares each capability with the policy and flag matrix" do
      expect(response).to match_policy_capabilities("home/index")
    end

    it "fails when an allowed capability disagrees with the policy" do
      page["props"]["can"]["widget.show"]["allowed"] = false

      expect(response).not_to match_policy_capabilities("home/index")
    end

    it "fails when the response has an extra capability" do
      page["props"]["can"]["widget.extra"] = { "allowed" => true, "reason" => nil }

      expect(response).not_to match_policy_capabilities("home/index")
    end

    it "fails without a props capture" do
      expect(fake_response(page)).not_to match_policy_capabilities("home/index")
    end
  end

  describe "within_budgets" do
    it "raises without a block" do
      expect { within_budgets.matches?(nil) }.to raise_error(ArgumentError, /needs a block/)
    end

    it "counts page calls against the named upstream budget" do
      expect {
        4.times { ActiveSupport::Notifications.instrument("upstream.call", name: :api, kind: :page) }
      }.not_to within_budgets
    end

    it "counts session refreshes separately from the page budget" do
      expect {
        4.times { ActiveSupport::Notifications.instrument("upstream.call", name: :api, kind: :session_refresh) }
      }.to within_budgets
    end
  end
end
