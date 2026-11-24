# frozen_string_literal: true

require "pg"
require "uri"

module Rafelo
  module Core
    # A restored database must not bring back sessions that were revoked after
    # the recovery point (OPS-07, SEC-16). Every restore, drills included, runs
    # this with the migration role before the app takes traffic. A direct
    # RESTORE_DATABASE_URL is opened on its own, so the task cannot truncate the
    # serving database by accident.
    class RestorePreparation
      class LiveDatabase < StandardError; end

      def initialize(connection: nil, url: nil, expected_role: nil)
        @connection = connection || (ActiveRecord::Base.connection if url.nil?)
        @url = url
        @expected_role = expected_role
        raise ArgumentError, "a connection or URL is required" if @connection.nil? && @url.blank?
      end

      def empty_sessions!
        if @url.present?
          with_restore_connection do |connection|
            refuse_live_database!(connection)
            refuse_wrong_role!(connection)
            connection.exec("TRUNCATE TABLE core_sessions")
          end
        else
          @connection.execute("TRUNCATE TABLE core_sessions")
        end
      end

      private

      def refuse_live_database!(connection)
        unless same_database?(connection_identity(connection), live_identity)
          return
        end

        raise LiveDatabase, "RESTORE_DATABASE_URL points at the live database; use a scratch target"
      end

      def refuse_wrong_role!(connection)
        expected = @expected_role.to_s
        return if expected.blank?

        current = connection.exec("SELECT current_user").getvalue(0, 0)
        return if current == expected

        raise LiveDatabase, "RESTORE_DATABASE_URL must connect as #{expected}, not #{current}"
      end

      def connection_identity(connection)
        row = connection.exec(<<~SQL).first
          SELECT current_database() AS database,
                 (SELECT oid FROM pg_database WHERE datname = current_database()) AS database_oid,
                 pg_postmaster_start_time()::text AS started_at
        SQL
        {
          database: row.fetch("database"),
          database_oid: row.fetch("database_oid").to_s,
          started_at: row.fetch("started_at")
        }
      end

      def live_identity
        row = ActiveRecord::Base.connection.select_one(<<~SQL)
          SELECT current_database() AS database,
                 (SELECT oid FROM pg_database WHERE datname = current_database()) AS database_oid,
                 pg_postmaster_start_time()::text AS started_at
        SQL
        {
          database: row.fetch("database"),
          database_oid: row.fetch("database_oid").to_s,
          started_at: row.fetch("started_at")
        }
      end

      def same_database?(target, live)
        target == live
      end

      def with_restore_connection
        connection = PG.connect(@url)
        yield connection
      ensure
        connection&.close
      end
    end
  end
end
