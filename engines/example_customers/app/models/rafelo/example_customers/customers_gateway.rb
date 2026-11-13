# frozen_string_literal: true

module Rafelo
  module ExampleCustomers
    # A domain gateway maps one upstream resource into public value objects
    # (BE-06). It is private to this engine; example_orders uses the public
    # Customer value object and component, never this gateway directly.
    class CustomersGateway < Rafelo::Core::Gateway
      upstream :api
      token :viewer

      def find(id)
        payload = parse(client.get("customers/#{id}").body).fetch("data")
        Customer.new(id: payload.fetch("id").to_s, name: payload.fetch("name"), tier: payload.fetch("tier"))
      end

      private

      def parse(body)
        JSON.parse(body.to_s)
      rescue JSON::ParserError, TypeError
        raise Rafelo::Core::ApplicationError.new("unexpected", "Upstream returned malformed JSON")
      end
    end
  end
end
