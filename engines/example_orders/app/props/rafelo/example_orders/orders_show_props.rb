# frozen_string_literal: true

module Rafelo
  module ExampleOrders
    class OrdersShowProps < Rafelo::Core::PageProps
      policy_class Rafelo::ExampleOrders::OrderPolicy
      capability Rafelo::ExampleOrders::Permissions::ORDER_UPDATE, :update?

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
              total: Rafelo::Core::Money.wire(@order.total_minor, @order.currency),
              issuedOn: @order.issued_on,
              version: @order.version
            },
            editHref: context.urls.route(:example_orders, :edit_order, id: @order.id),
            indexPath: context.urls.route(:example_orders, :orders)
          },
          meta: {},
          query: {},
          pagination: nil,
          can: capabilities(Rafelo::ExampleOrders::Permissions::ORDER_UPDATE)
        }
      end
    end
  end
end
