# frozen_string_literal: true

module Rafelo
  module Core
    # Monthly partitions for core_audit_events and their retention. The parent
    # table, trigger, and functions live in structure.sql; partitions are
    # created here so a new month never changes the dump (OPS-08).
    class AuditPartitions
      TABLE = "core_audit_events"
      DEFAULT_TABLE = "core_audit_events_default"
      MONTH_PATTERN = /\Acore_audit_events_(\d{4})_(\d{2})\z/

      class DefaultPartitionOccupied < StandardError; end

      def initialize(connection: nil)
        @connection = connection || self.class.default_connection
      end

      def self.default_connection
        Rails.env.production? ? MigrationRecord.connection : ActiveRecord::Base.connection
      end

      def ensure!(at: Time.current, months_ahead: 2, restrict_role: Rails.application.config.x.database.runtime_role)
        create_default!
        (0...months_ahead).each do |offset|
          create_month!(at.beginning_of_month + offset.months)
        end
        restrict_grants!(role: restrict_role) if restrict_role.present?
      end

      def default_rows
        @connection.select_value("SELECT count(*) FROM #{DEFAULT_TABLE}").to_i
      end

      def alert_default!
        rows = default_rows
        return false unless rows.positive?

        Rails.error.report(
          DefaultPartitionOccupied.new("#{DEFAULT_TABLE} holds #{rows} audit rows"),
          handled: false,
          context: { rows: rows }
        )
        true
      end

      def drop_old_partitions!(at: Time.current, retention_days: Rails.application.config.x.audit.retention_days)
        cutoff = at.beginning_of_month - retention_days.days
        partitions.each do |name, month|
          next if month >= cutoff.beginning_of_month

          @connection.execute("DROP TABLE #{@connection.quote_table_name(name)}")
        end
      end

      def partitions
        @connection.select_rows(<<~SQL).filter_map do |name, bound|
          SELECT child.relname, pg_get_expr(child.relpartbound, child.oid)
          FROM pg_inherits
          JOIN pg_class parent ON parent.oid = pg_inherits.inhparent
          JOIN pg_class child ON child.oid = pg_inherits.inhrelid
          WHERE parent.relname = '#{TABLE}'
        SQL
          next unless name.match?(MONTH_PATTERN)

          first_day = bound[/FROM \('([^']+)'\)/, 1]
          next unless first_day

          [ name, Time.zone.parse(first_day).beginning_of_month ]
        end.to_h
      end

      # The runtime role owns no table. On the audit parent and every
      # partition it may only INSERT and SELECT, whatever default privileges
      # a newly created partition inherited (OPS-08).
      def restrict_grants!(role:)
        role = role.to_s
        return false if role.blank?

        current = @connection.select_value("SELECT current_user").to_s
        return false if role == current

        quoted_role = @connection.quote_table_name(role)
        exists = @connection.select_value("SELECT 1 FROM pg_roles WHERE rolname = #{@connection.quote(role)}")
        return false unless exists

        names = [ TABLE, DEFAULT_TABLE ] + partitions.keys
        names << "core_audits" if @connection.table_exists?("core_audits")

        names.each do |name|
          @connection.execute("REVOKE UPDATE, DELETE, TRUNCATE ON #{@connection.quote_table_name(name)} FROM #{quoted_role}")
          @connection.execute("GRANT SELECT, INSERT ON #{@connection.quote_table_name(name)} TO #{quoted_role}")
        end
        true
      end

      private

      def create_default!
        @connection.execute(<<~SQL)
          CREATE TABLE IF NOT EXISTS #{DEFAULT_TABLE}
            PARTITION OF #{TABLE} DEFAULT
        SQL
      end

      def create_month!(month)
        name = "core_audit_events_#{month.strftime("%Y_%m")}"
        @connection.execute(<<~SQL)
          CREATE TABLE IF NOT EXISTS #{name}
            PARTITION OF #{TABLE}
            FOR VALUES FROM ('#{month.strftime("%Y-%m-%d")}') TO ('#{month.next_month.strftime("%Y-%m-%d")}')
        SQL
      rescue ActiveRecord::StatementInvalid => error
        if error.cause.is_a?(PG::CheckViolation) && default_rows.positive?
          alert_default!
          raise DefaultPartitionOccupied, "#{DEFAULT_TABLE} holds rows for #{month.strftime("%Y-%m")}: #{error.message}"
        end

        raise
      end
    end
  end
end
