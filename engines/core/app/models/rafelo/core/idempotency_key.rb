# frozen_string_literal: true

module Rafelo
  module Core
    class IdempotencyKey < ActiveRecord::Base
      FORMAT_VERSION = 1
      READABLE_FORMAT_VERSIONS = [ FORMAT_VERSION ].freeze

      self.table_name = "core_idempotency_keys"

      STATUSES = %w[pending succeeded failed unknown].freeze

      scope :readable_format, -> { where(format_version: READABLE_FORMAT_VERSIONS) }

      validates :status, inclusion: { in: STATUSES }

      def self.sweep
        where("expires_at < ?", Time.current).in_batches(of: 1_000).delete_all
      end
    end
  end
end
