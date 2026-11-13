# frozen_string_literal: true

module Rafelo
  module Core
    class IdempotencySweepJob < BaseJob
      queue_as :default

      def perform
        IdempotencyKey.sweep
      end
    end
  end
end
