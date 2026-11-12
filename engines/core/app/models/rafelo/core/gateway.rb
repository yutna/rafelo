# frozen_string_literal: true

module Rafelo
  module Core
    class Gateway
      class << self
        def upstream(name = nil)
          if name
            key = name.to_sym
            unless Rails.application.config.x.upstreams.key?(key)
              raise ArgumentError, "unknown upstream #{key.inspect}"
            end
            @upstream = key
          end
          @upstream || raise(ArgumentError, "#{self.name} declares no upstream")
        end

        def token(kind = nil)
          if kind
            unless %i[viewer service].include?(kind.to_sym)
              raise ArgumentError, "unknown token kind #{kind.inspect}"
            end
            @token = kind.to_sym
          end
          @token || :viewer
        end
      end

      attr_reader :budget, :request_id, :trace_id

      def initialize(token_provider:, budget:, request_id:, trace_id:)
        @token_provider = token_provider
        @budget = budget
        @request_id = request_id
        @trace_id = trace_id
      end

      def client
        UpstreamClient.for(
          self.class.upstream,
          config: Rails.application.config.x.upstreams.fetch(self.class.upstream),
          token_provider: @token_provider,
          budget: @budget,
          request_id: @request_id,
          trace_id: @trace_id
        )
      end
    end
  end
end
