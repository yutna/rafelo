# frozen_string_literal: true

module Rafelo
  module Core
    module Throttling
      extend ActiveSupport::Concern

      included do
        class_attribute :throttle_limits, instance_accessor: false, default: {}.freeze
      end

      class_methods do
        # One named limit per action. Rails keys the counter by controller,
        # name and subject, so reusing a name on one action would share it.
        def throttle(to:, within:, only:, by: -> { request.remote_ip }, name: nil)
          actions = Array(only).map(&:to_sym)
          name ||= actions.join(",")

          actions.each do |action|
            existing = Array(throttle_limits[action])
            next if existing.none? { |limit| limit[:name] == name }

            raise ArgumentError, "#{self.name}##{action} already has a limit named #{name.inspect}; pass name:"
          end

          # prepend: limits run before every base callback (BE-24), so a
          # throttled request loads no session and triggers no refresh.
          rate_limit(to:, within:, only: actions, by:, name:, prepend: true,
                     with: -> { render_error("request.throttled") })

          self.throttle_limits = throttle_limits.merge(
            actions.index_with { |action| [ *Array(throttle_limits[action]), { name:, to:, within: } ].freeze }
          ).freeze
        end
      end
    end
  end
end
