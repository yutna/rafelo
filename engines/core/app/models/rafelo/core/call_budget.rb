# frozen_string_literal: true

module Rafelo
  module Core
    class CallBudget
      def initialize(limits = {})
        @limits = limits.transform_keys(&:to_sym)
        @counts = Hash.new(0)
        @mutex = Mutex.new
      end

      def consume!(upstream)
        name = upstream.to_sym
        @mutex.synchronize do
          limit = @limits.fetch(name, 0)
          raise ApplicationError.new("request.throttled") if @counts[name] >= limit

          @counts[name] += 1
        end
      end

      def count(upstream)
        @mutex.synchronize { @counts[upstream.to_sym] }
      end
    end
  end
end
