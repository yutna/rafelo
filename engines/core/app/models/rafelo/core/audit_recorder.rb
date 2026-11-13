# frozen_string_literal: true

require "ipaddr"

module Rafelo
  module Core
    # One row per audited request, with the allow-listed fields only. A
    # request-scoped marker makes a 403/raise replace, not duplicate, a write
    # row (OPS-08, BE-13).
    class AuditRecorder
      FAMILIES = {
        /Edg\//i => "edge",
        /Firefox\//i => "firefox",
        /Chrome\//i => "chrome",
        /Safari\//i => "safari"
      }.freeze

      def self.record(controller:, event:, outcome:, target: nil, viewer_id: nil, resource: nil,
                      action: nil, upstream_id: nil, policy: nil, page: nil)
        return if Current.audit_recorded

        request = controller.request
        AuditEvent.create!(
          occurred_at: Time.current,
          event: event,
          outcome: outcome,
          target: target.to_s.presence,
          viewer_id: (viewer_id || Current.viewer&.id)&.to_s,
          request_id: Current.request_id.to_s.presence || request.request_id,
          trace_id: Current.trace_id.to_s.presence || request.env["rafelo.trace_id"].to_s.presence || request.request_id,
          ip: truncate_ip(request.remote_ip),
          user_agent_family: family(request.user_agent),
          resource: resource || inferred_resource(controller),
          action: action || inferred_action(controller),
          upstream_id: upstream_id || request.env["rafelo.audit.upstream_id"].to_s.presence,
          policy: policy.to_s.presence,
          page: page || request.env["rafelo.page"].to_s.presence,
          created_at: Time.current,
          format_version: AuditEvent::FORMAT_VERSION
        )
        Current.audit_recorded = true
      end

      def self.inferred_resource(controller)
        controller.controller_path.to_s.presence if controller.respond_to?(:controller_path)
      end

      def self.inferred_action(controller)
        controller.action_name.to_s.presence if controller.respond_to?(:action_name)
      end

      def self.truncate_ip(value)
        address = IPAddr.new(value.to_s)
        address = address.native if address.ipv4_mapped?
        prefix = address.ipv4? ? 24 : 48
        "#{IPAddr.new("#{address}/#{prefix}")}/#{prefix}"
      rescue IPAddr::Error, ArgumentError
        nil
      end

      def self.family(user_agent)
        agent = user_agent.to_s
        return "other" if agent.blank? || agent.bytesize > 512

        FAMILIES.each { |pattern, name| return name if pattern.match?(agent) }
        "other"
      end
    end
  end
end
