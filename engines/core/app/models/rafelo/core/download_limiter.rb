# frozen_string_literal: true

require "concurrent"

module Rafelo
  module Core
    class DownloadLimiter
      class << self
        def acquire
          semaphore.try_acquire
        end

        def release(permit)
          semaphore.release if permit
        end

        def reset!
          @semaphore = nil
        end

        private

        def semaphore
          @semaphore ||= Concurrent::Semaphore.new(Rails.application.config.x.downloads.max_concurrent)
        end
      end
    end
  end
end
