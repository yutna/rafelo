# frozen_string_literal: true

module Rafelo
  module Core
    class IdempotencyKey < ActiveRecord::Base
      self.table_name = "core_idempotency_keys"

      STATUSES = %w[pending succeeded failed unknown].freeze

      validates :status, inclusion: { in: STATUSES }

      def self.sweep
        where("expires_at < ?", Time.current).in_batches(of: 1_000).delete_all
      end
    end
  end
end
