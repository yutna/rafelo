# frozen_string_literal: true

class SessionsNewProps < Rafelo::Core::PageProps
  def initialize(context:, csrf_token:, error: nil, return_to: nil)
    super(context:)
    @csrf_token = csrf_token
    @error = error
    @return_to = return_to
  end

  def envelope
    { data: { error: @error, formHref: form_href }, meta: { csrfToken: @csrf_token }, query: {}, pagination: nil, can: {} }
  end

  private

  def form_href
    path = "/#{@context.locale}/sign_in"
    return path if @return_to.blank?

    "#{path}?return_to=#{ERB::Util.url_encode(@return_to)}"
  end
end
