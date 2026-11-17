# frozen_string_literal: true

module RuboCop
  module Cop
    module Rafelo
      # ENV and Rails credentials are read at one configuration boundary
      # (ARCH-01, BE-04, BE-08).
      class EnvOnlyInConfig < Base
        MSG = "Rafelo/EnvOnlyInConfig: read ENV and Rails credentials only in config/."

        def on_send(node)
          return unless env_read?(node) || credentials_read?(node)

          add_offense(node)
        end

        private

        def env_read?(node)
          return false unless %i[[] fetch].include?(node.method_name)

          receiver = node.receiver
          receiver&.const_type? && receiver.const_name == "ENV"
        end

        def credentials_read?(node)
          node.receiver&.source.to_s.start_with?("Rails.application.credentials")
        end
      end
    end
  end
end
