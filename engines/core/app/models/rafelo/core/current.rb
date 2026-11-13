# frozen_string_literal: true

module Rafelo
  module Core
    class Current < ActiveSupport::CurrentAttributes
      attribute :request_id, :trace_id, :trace_sampled, :session, :viewer, :permissions, :token_provider, :call_budget, :audit_recorded
    end
  end
end
