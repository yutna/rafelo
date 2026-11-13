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
        meta: {},
        query: {},
        pagination: nil,
        can: {}
      }
    end
  end
end
