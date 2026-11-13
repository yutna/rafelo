# frozen_string_literal: true

module Rafelo
  module Core
    # Creates upcoming monthly partitions, alerts when the DEFAULT partition
    # catches rows, and drops partitions past the audit retention (OPS-07,
    # OPS-08). Production runs this hourly; development and test ensure
    # partitions at boot.
    class AuditPartitionMaintenanceJob < BaseJob
      queue_as :default

      def perform
        partitions = AuditPartitions.new
        partitions.ensure!(
          months_ahead: Rails.application.config.x.audit.partition_months_ahead,
          restrict_role: Rails.application.config.x.database.runtime_role
        )
        partitions.alert_default!
        partitions.drop_old_partitions!
      end
    end
  end
end
