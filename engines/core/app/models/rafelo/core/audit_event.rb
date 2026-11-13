# frozen_string_literal: true

module Rafelo
  module Core
    class AuditEvent < ActiveRecord::Base
      FORMAT_VERSION = 1
      READABLE_FORMAT_VERSIONS = [ FORMAT_VERSION ].freeze

      self.table_name = "core_audits"
      self.record_timestamps = false

      scope :readable_format, -> { where(format_version: READABLE_FORMAT_VERSIONS) }

      validates :event, :outcome, :occurred_at, presence: true
    end
  end
end
