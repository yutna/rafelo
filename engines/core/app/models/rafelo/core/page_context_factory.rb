# frozen_string_literal: true

module Rafelo
  module Core
    class PageContextFactory
      def self.build(session:, flags:, locale:, request_id:, urls:)
        PageContext.new(
          viewer: session&.viewer || Current.viewer,
          permissions: session&.permission_set || Current.permissions,
          flags: flags,
          locale: locale,
          request_id: request_id,
          urls: urls
        )
      end
    end
  end
end
