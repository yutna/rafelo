# frozen_string_literal: true

require "yaml"

module Rafelo
  module Core
    # The runtime call budgets from config/budgets.yml (BE-16). Page calls and
    # refresh/grant calls have separate limits, so a mid-action refresh never
    # consumes a page slot. Every named upstream must have a page budget;
    # a missing one fails boot instead of becoming a silent 0/429.
    class Budgets
      def self.load(root: Rails.root)
        data = YAML.safe_load_file(root.join("config/budgets.yml"), aliases: true)
        new(data)
      end

      def initialize(data)
        @data = data.is_a?(Hash) ? data : {}
      end

      def upstream_calls
        fetch("defaults", "upstream_calls_per_request")
      end

      def refresh_calls
        fetch("defaults", "refresh_calls_per_request")
      end

      def job_calls
        fetch("jobs", "upstream_calls_per_request")
      end

      def validate!(upstreams)
        names = Array(upstreams).map(&:to_s)
        {
          "upstream_calls_per_request" => upstream_calls,
          "refresh_calls_per_request" => refresh_calls,
          "jobs.upstream_calls_per_request" => job_calls
        }.each do |key, limits|
          missing = names - limits.keys
          next if missing.empty?

          raise "config/budgets.yml is missing #{key} for #{missing.join(", ")}"
        end
      end

      private

      def fetch(section, key)
        @data.fetch(section, {}).fetch(key, {})
      end
    end
  end
end
