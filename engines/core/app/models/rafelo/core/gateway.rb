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
            if @token == :service
              config = Rails.application.config.x.upstreams.fetch(upstream)
              unless config.service_token_gateways.include?(name)
                raise ArgumentError, "#{name} is not allow-listed for a service token on #{upstream}"
              end
            end
          end
          @token || :viewer
        end
      end

      attr_reader :budget, :request_id, :trace_id

      def initialize(token_provider:, budget:, request_id:, trace_id:)
        expected_service = self.class.token == :service
        unless token_provider.respond_to?(:service?) && token_provider.service? == expected_service
          raise ArgumentError, "#{self.class.name} requires a #{expected_service ? 'service' : 'viewer'} token provider"
        end
        @token_provider = token_provider
        @budget = budget
        @request_id = request_id
        @trace_id = trace_id
      end

      def client
        @client ||= UpstreamClient.for(
          self.class.upstream,
          config: Rails.application.config.x.upstreams.fetch(self.class.upstream),
          token_provider: @token_provider,
          budget: @budget,
          request_id: @request_id,
          trace_id: @trace_id,
          deadline: @budget.respond_to?(:deadline) ? @budget.deadline : nil
        )
      end
    end
  end
end
