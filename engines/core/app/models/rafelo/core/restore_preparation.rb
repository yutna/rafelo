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

      def initialize(connection: nil, url: nil)
        @connection = connection || (ActiveRecord::Base.connection if url.nil?)
        @url = url
        raise ArgumentError, "a connection or URL is required" if @connection.nil? && @url.blank?
      end

      def empty_sessions!
        if @url.present?
          refuse_live_database!
          with_restore_connection { |connection| connection.exec("TRUNCATE TABLE core_sessions") }
        else
          @connection.execute("TRUNCATE TABLE core_sessions")
        end
      end

      private

      def refuse_live_database!
        if same_database?(target, live_database)
          raise LiveDatabase, "RESTORE_DATABASE_URL points at the live database; use a scratch target"
        end
      end

      def target
        @target ||= URI.parse(@url)
      rescue URI::InvalidURIError
        raise LiveDatabase, "RESTORE_DATABASE_URL is not a valid PostgreSQL URL"
      end

      def live_database
        @live_database ||= ActiveRecord::Base.connection_db_config.configuration_hash
      end

      def same_database?(target, live)
        target_host = target.host.presence || "localhost"
        live_host = live[:host].presence || "localhost"
        target_port = target.port || 5432
        live_port = (live[:port].presence || 5432).to_i
        target_database = target.path.to_s.delete_prefix("/")
        live_database_name = live[:database].to_s

        target_host == live_host && target_port == live_port && target_database == live_database_name
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
