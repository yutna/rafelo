# frozen_string_literal: true

module Rafelo
  module ExampleOrders
    class OrdersShowProps < Rafelo::Core::PageProps
      def initialize(context:, order:)
        super(context: context)
        @order = order
      end

      def envelope
        {
          data: {
            order: {
              id: @order.id,
              number: @order.number,
              customer: { id: @order.customer_id, name: @order.customer_name, tier: @order.customer_tier },
              status: @order.status,
              total: { minor: @order.total_minor, currency: @order.currency, exponent: 2 },
              issuedOn: @order.issued_on,
              version: @order.version
            },
            editHref: context.urls.route(:example_orders, :edit_order, id: @order.id),
            indexPath: context.urls.route(:example_orders, :orders)
          },
          meta: {},
          query: {},
          pagination: nil,
          can: {}
        }
      end
    end
  end
end
