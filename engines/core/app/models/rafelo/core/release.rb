# frozen_string_literal: true

module Rafelo
  module Core
    # The release tag joins server and client error reports (OPS-03): the
    # VERSION file plus the Vite digest the browser uses as Inertia's version.
    class Release
      @mutex = Mutex.new
      @value = nil

      class << self
        def call
          @mutex.synchronize { @value ||= "#{version}:#{AssetVersion.call}" }
        end

        def version
          @version ||= Rails.root.join("VERSION").read.strip
        end
      end
    end
  end
end
