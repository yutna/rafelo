# frozen_string_literal: true

module Rafelo
  module Core
    # The Inertia asset version, computed once per process. `ViteRuby.digest`
    # re-hashes the watched sources inside `Dir.chdir`; calling it per request
    # makes concurrent Puma threads raise "conflicting chdir".
    class AssetVersion
      @mutex = Mutex.new
      @version = nil

      class << self
        def call
          @mutex.synchronize { @version ||= ViteRuby.digest }
        end

        def reset!
          @mutex.synchronize { @version = nil }
        end
      end
    end
  end
end
