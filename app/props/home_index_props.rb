# frozen_string_literal: true

class HomeIndexProps < Rafelo::Core::PageProps
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
