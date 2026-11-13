# frozen_string_literal: true

module DummyEngine
  class WidgetsController < Rafelo::Core::BaseController
    layout "application"
    before_action :skip_authorization, only: %i[index missing_key extra_key set_flash whoami expired create validation conflict boom not_found upstream]
    throttle to: 30, within: 1.minute, only: %i[create validation conflict boom crash upstream], name: "dummy/write"

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

    def create
      form = DummyWidgetForm.new(params.permit(:name, :token))
      if form.invalid?
        return redirect_after_write("/en/dummy/widgets", errors: form.error_messages)
      end

      Rafelo::Core::IdempotencyClaim.call(
        self,
        token: form.token,
        payload: form.payload,
        back: "/en/dummy/widgets"
      ) do
        redirect_after_write("/en/dummy/widgets", notice: "Widget created.")
      end
    end

    def validation
      form = DummyWidgetForm.new(name: "")
      error = Rafelo::Core::ValidationFailed.new("name" => :too_long, "mystery" => :taken)
      redirect_after_write("/en/dummy/widgets", errors: form.translate(error.field_codes))
    end

    def conflict
      form = DummyWidgetForm.new
      redirect_after_write("/en/dummy/widgets", errors: form.translate(base: :conflict))
    end

    def boom
      raise Rafelo::Core::ApplicationError.new("unexpected")
    end

    def not_found
      raise Rafelo::Core::ApplicationError.new("resource.not_found")
    end

    def crash
      authorize :home, :show?
      raise "unhandled probe"
    end

    def upstream
      Rafelo::Core::UpstreamClient.for(
        :api,
        config: Rails.application.config.x.upstreams.fetch(:api),
        token_provider: Rafelo::Core::NullTokenProvider.new
      ).post("widgets", body: "{}")
      redirect_after_write("/en/dummy/widgets", notice: "Widget created.")
    rescue Rafelo::Core::ValidationFailed => error
      redirect_after_write("/en/dummy/widgets", errors: DummyWidgetForm.new.translate(error.field_codes))
    rescue Rafelo::Core::ApplicationError => error
      raise unless error.code == "resource.conflict"

      redirect_after_write("/en/dummy/widgets", errors: { "base" => I18n.t("core.errors.fields.conflict") })
    end

    def upstream_forbidden
      authorize :home, :show?
      Rafelo::Core::UpstreamClient.for(
        :api,
        config: Rails.application.config.x.upstreams.fetch(:api),
        token_provider: Rafelo::Core::Current.token_provider,
        budget: Rafelo::Core::Current.call_budget ||= Rafelo::Core::CallBudget.new(api: 3),
        request_id: Rafelo::Core::Current.request_id,
        trace_id: Rafelo::Core::Current.trace_id
      ).get("forbidden")
    end

    def set_flash
      flash[:notice] = "Dummy notice"
      redirect_to "/en/dummy/widgets", status: :see_other
    end
  end
end
