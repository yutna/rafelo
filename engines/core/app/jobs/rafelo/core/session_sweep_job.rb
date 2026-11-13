# frozen_string_literal: true

module Rafelo
  module Core
    class SessionSweepJob < BaseJob
      queue_as :default

      def perform
        Session.sweep
      end
    end
  end
end
