# frozen_string_literal: true

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
          Executor.reset_semaphores!
        end

        private

        def semaphore
          Executor.semaphore(Rails.application.config.x.downloads.max_concurrent)
        end
      end
    end
  end
end
