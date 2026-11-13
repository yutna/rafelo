# frozen_string_literal: true

module Rafelo
  module Core
    # A restored database must not bring back sessions that were revoked after
    # the recovery point (OPS-07, SEC-16). Every restore, drills included, runs
    # this with the migration role before the app takes traffic.
    class RestorePreparation
      def initialize(connection: ActiveRecord::Base.connection)
        @connection = connection
      end

      def empty_sessions!
        @connection.execute("TRUNCATE TABLE core_sessions")
      end
    end
  end
end
