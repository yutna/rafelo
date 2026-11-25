# frozen_string_literal: true

module Rafelo
  module Core
    class PageContextFactory
      # Viewer, permissions, and session id come from the one session (BE-01,
      # BE-04). Without a session the viewer and id are nil and the permission
      # set is empty, so a prop object never has to guard for nil permissions.
      def self.build(session: nil, trace_id: nil, flags:, locale:, request_id:, urls:)
        PageContext.new(
          viewer: session&.viewer,
          permissions: session ? session.permission_set : PermissionSet.new([]),
          flags: flags,
          locale: locale,
          request_id: request_id,
          trace_id: trace_id,
          session_id: session&.id,
          urls: urls
        )
      end
    end
  end
end
