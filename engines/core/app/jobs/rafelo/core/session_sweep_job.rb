# frozen_string_literal: true

module Rafelo
  module Core
    class SessionSweepJob < ActiveJob::Base
      queue_as :default

      def perform
        Session.sweep
      end
    end
  end
end
