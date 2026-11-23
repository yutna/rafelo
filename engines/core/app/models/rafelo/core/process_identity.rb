# frozen_string_literal: true

require "socket"

module Rafelo
  module Core
    # The process identity every report and metric carries (OPS-01, OPS-04).
    # A host runs several Puma workers and Solid Queue processes, each with its
    # own metrics; the role says which deployment role produced the record.
    class ProcessIdentity
      def self.to_h
        {
          host: Socket.gethostname,
          pid: Process.pid,
          role: Rails.application.config.x.process.role.to_s.presence || "unknown"
        }
      end
    end
  end
end
