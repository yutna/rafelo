# frozen_string_literal: true

module Rafelo
  module Core
    # A download stopped waiting past the request deadline: the viewer stopped
    # draining the chunk queue, or no first chunk arrived. It is a local pace
    # condition, not an upstream failure; the producer throws out of the
    # upstream call so the breaker records neither a failure nor a success
    # (BE-05, BE-16, BE-18).
    class DownloadStalled < ApplicationError
      def initialize
        super("upstream.timeout")
      end
    end
  end
end
