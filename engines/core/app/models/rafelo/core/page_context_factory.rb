# frozen_string_literal: true

module Rafelo
  module Core
    class PageContextFactory
      def self.build(viewer:, permissions:, trace_id:, session_id:, flags:, locale:, request_id:, urls:)
        PageContext.new(
          viewer: viewer,
          permissions: permissions,
          flags: flags,
          locale: locale,
          request_id: request_id,
          trace_id: trace_id,
          session_id: session_id,
          urls: urls
        )
      end
    end
  end
end
