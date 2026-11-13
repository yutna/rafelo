# frozen_string_literal: true

module Rafelo
  module ExampleOrders
    class OrdersGateway < Rafelo::Core::Gateway
      upstream :api
      token :viewer

      def list(query)
        payload = parse(
          client.get(
            "orders",
            params: {
              page: query.page,
              per_page: query.per_page,
              status: query.filters["status"],
              sort: query.sort,
              direction: query.direction
            }.compact
          ).body
        )
        items = Array(payload["items"]).map { |row| order(row) }
        OrdersPage.new(items: items, total: payload.dig("pagination", "total").to_i)
      end

      def find(id)
        order(parse(client.get("orders/#{id}").body).fetch("data"))
      end

      def create(payload:, idempotency_key:)
        response = client.post(
          "orders",
          body: payload.to_json,
          headers: { "Content-Type" => "application/json" },
          idempotency_key: idempotency_key
        )
        order(parse(response.body).fetch("data"))
      end

      def update(id:, payload:, idempotency_key:, if_match:)
        response = client.patch(
          "orders/#{id}",
          body: payload.to_json,
          headers: { "Content-Type" => "application/json" },
          idempotency_key: idempotency_key,
          if_match: if_match
        )
        order(parse(response.body).fetch("data"))
      end

      private

      def order(row)
        customer = row.fetch("customer", {})
        Order.new(
          id: row.fetch("id").to_s,
          number: row.fetch("number"),
          customer_id: customer.fetch("id").to_s,
          customer_name: customer.fetch("name"),
          customer_tier: customer.fetch("tier"),
          status: row.fetch("status"),
          total_minor: row.fetch("total_minor"),
          currency: row.fetch("currency"),
          issued_on: row.fetch("issued_on"),
          version: row.fetch("version")
        )
      end

      def parse(body)
        JSON.parse(body.to_s)
      rescue JSON::ParserError, TypeError
        raise Rafelo::Core::ApplicationError.new("unexpected", "Upstream returned malformed JSON")
      end
    end
  end
end
