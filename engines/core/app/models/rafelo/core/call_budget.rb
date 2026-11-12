# frozen_string_literal: true

module Rafelo
  module Core
    class CallBudget
      def initialize(limits = {})
        @limits = limits.transform_keys(&:to_sym)
        @counts = Hash.new(0)
      end

      def consume!(upstream)
        name = upstream.to_sym
        limit = @limits.fetch(name, 0)
        raise ApplicationError.new("request.throttled") if @counts[name] >= limit

        @counts[name] += 1
      end

      def count(upstream)
        @counts[upstream.to_sym]
      end
    end
  end
end
