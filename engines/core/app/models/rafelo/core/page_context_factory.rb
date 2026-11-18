# frozen_string_literal: true

module Rafelo
  module Core
    class PageContextFactory
      def self.build(session: nil, viewer: nil, permissions: nil, trace_id: nil, session_id: nil,
                     flags:, locale:, request_id:, urls:)
        PageContext.new(
          viewer: viewer || session&.viewer,
          permissions: permissions || session&.permission_set,
          flags: flags,
          locale: locale,
          request_id: request_id,
          trace_id: trace_id,
          session_id: session_id || session&.id,
          urls: urls
        )
      end
    end
  end
end
