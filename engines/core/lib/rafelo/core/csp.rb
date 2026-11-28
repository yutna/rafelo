# frozen_string_literal: true

module Rafelo
  module Core
    # `csp.report_only` is the one typed setting whose default is the safe
    # value: a config/core.yml written before the key existed boots with the
    # policy enforced, and only a present, malformed value raises (BE-08,
    # SEC-05). config/core.yml is app-owned, so a customized copy keeps its
    # file across bin/kernel_update and may lack the key.
    module Csp
      def self.report_only(csp)
        return false if csp.nil?
        unless csp.is_a?(Hash)
          raise ArgumentError, "config/core.yml csp must be a mapping with report_only: true or false"
        end

        value = csp[:report_only]
        return false if value.nil?
        return value if value == true || value == false

        raise ArgumentError, "config/core.yml csp.report_only (CSP_REPORT_ONLY) must be true or false"
      end
    end
  end
end
