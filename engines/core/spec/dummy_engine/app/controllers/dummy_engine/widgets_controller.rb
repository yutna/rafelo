# frozen_string_literal: true

module DummyEngine
  class WidgetsController < Rafelo::Core::BaseController
    layout "application"
    before_action :skip_authorization, only: %i[index missing_key extra_key set_flash whoami expired]

    def index
      render_page "dummy/widgets", props: DummyWidgetsProps.new(context: page_context, message: "dummy")
    end

    def missing_key
      render_page "dummy/widgets", props: { data: {}, meta: {}, query: {}, can: {} }
    end

    def extra_key
      render_page "dummy/widgets", props: {
        data: {}, meta: {}, query: {}, pagination: nil, can: {}, extra: true
      }
    end

    def denied
      authorize :home, :missing?
      render plain: "never"
    end

    def whoami
      render plain: Rafelo::Core::Current.viewer&.id.to_s
    end

    def expired
      raise Rafelo::Core::ApplicationError.new("auth.expired")
    end

    def set_flash
      flash[:notice] = "Dummy notice"
      redirect_to "/en/dummy/widgets", status: :see_other
    end
  end
end
