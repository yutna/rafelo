# frozen_string_literal: true

module Rafelo
  module Core
    class ExportSweepJob < BaseJob
      queue_as :default

      def perform
        Export.purge_expired
      end
    end
  end
end
