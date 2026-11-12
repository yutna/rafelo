# frozen_string_literal: true

module Rafelo
  module Core
    class Current < ActiveSupport::CurrentAttributes
      attribute :request_id, :trace_id, :session, :viewer, :permissions
    end
  end
end
