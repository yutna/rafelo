# frozen_string_literal: true

require "ipaddr"

module Rafelo
  module Core
    # An address is internal when it is a loopback, private, or link-local
    # address. A scrape endpoint that must not answer the public edge checks
    # the address ActionDispatch::RemoteIp resolved, never a header a client
    # can forge (OPS-04, SEC-13).
    module InternalNetwork
      module_function

      def include?(value)
        address = IPAddr.new(value.to_s)
        address = address.native if address.ipv4_mapped?
        address.loopback? || address.private? || address.link_local?
      rescue IPAddr::Error
        false
      end
    end
  end
end
