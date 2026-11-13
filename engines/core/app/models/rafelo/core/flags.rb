# frozen_string_literal: true

module Rafelo
  module Core
    class Flags
      def self.load(raw)
        raw.to_h.deep_symbolize_keys.freeze
      end

      def self.current
        Rails.application.config.x.flags
      end

      def self.enabled?(name)
        current.fetch(name.to_sym, false)
      end
    end
  end
end
