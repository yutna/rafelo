# frozen_string_literal: true

module Rafelo
  module Core
    # A download viewer stopped draining the chunk queue past the request
    # deadline. It is a local pace condition, not an upstream failure: the
    # breaker skips it and the upstream metrics do not count it (BE-05, BE-16,
    # BE-18).
    class DownloadStalled < ApplicationError
      def initialize
        super("upstream.timeout")
      end
    end
  end
end
