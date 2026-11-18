# frozen_string_literal: true

module DummyEngine
  class DummyWidgetsProps < Rafelo::Core::PageProps
    def initialize(context:, message:)
      super(context:)
      @message = message
    end

    def envelope
      {
        data: { message: @message },
        meta: { formToken: Rafelo::Core::FormToken.issue(session_id: @context.session_id) },
        query: {},
        pagination: nil,
        can: {}
      }
    end
  end
end
