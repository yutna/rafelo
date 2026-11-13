# frozen_string_literal: true

module Rafelo
  module Core
    class NullTokenProvider
      def token = nil
      def service? = false
    end
  end
end
