# frozen_string_literal: true

module Rafelo
  module Core
    class ViewerTokenProvider
      def initialize(session)
        @session = session
      end

      def token = @session.access_token
      def service? = false
    end
  end
end
