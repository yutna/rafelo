# frozen_string_literal: true

class SessionsNewProps < Rafelo::Core::PageProps
  def initialize(context:, error: nil)
    super(context:)
    @error = error
  end

  def envelope
    { data: { error: @error }, meta: {}, query: {}, pagination: nil, can: {} }
  end
end
