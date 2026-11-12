# frozen_string_literal: true

require "yaml"

module Rafelo
  module Core
    module Locales
      module_function

      def configuration
        @configuration ||= YAML.load_file(Rails.root.join("config", "locales.yml"))
      end

      def available
        configuration.fetch("available").map(&:to_s)
      end

      def default
        configuration.fetch("default").to_s
      end

      def segment_pattern
        configuration.fetch("segment_pattern")
      end

      def available?(value)
        available.include?(value.to_s)
      end

      def locale_segment?(value)
        value.to_s.match?(/\A#{segment_pattern}\z/)
      end

      def route_constraint
        Regexp.new(segment_pattern)
      end
    end
  end
end
