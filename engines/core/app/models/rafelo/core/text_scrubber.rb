# frozen_string_literal: true

module Rafelo
  module Core
    # Removes the credential classes the client report may carry (OPS-03):
    # a Bearer credential, a JWT, an email address and any 32+ base64url run.
    module TextScrubber
      PATTERNS = [
        /\bBearer\s+[A-Za-z0-9._~+\/-]+=*/i,
        /\beyJ[A-Za-z0-9_-]*\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\b/,
        /\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b/,
        /[A-Za-z0-9_-]{32,}/
      ].freeze

      def self.call(value)
        PATTERNS.reduce(value.to_s) { |text, pattern| text.gsub(pattern, "[FILTERED]") }
      end

      def self.cut(value, limit)
        call(value).first(limit)
      end
    end
  end
end
