# frozen_string_literal: true

class SessionsNewProps < Rafelo::Core::PageProps
  def initialize(context:, csrf_token:, error: nil)
    super(context:)
    @csrf_token = csrf_token
    @error = error
  end

  def envelope
    { data: { error: @error }, meta: { csrfToken: @csrf_token }, query: {}, pagination: nil, can: {} }
  end
end
