# frozen_string_literal: true

module Rafelo
  module Core
    class AuditEvent < ActiveRecord::Base
      self.table_name = "core_audits"
      self.record_timestamps = false

      validates :event, :outcome, :occurred_at, presence: true
    end
  end
end
