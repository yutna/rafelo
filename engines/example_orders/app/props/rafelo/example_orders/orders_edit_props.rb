# frozen_string_literal: true

module Rafelo
  module ExampleOrders
    class OrdersEditProps < Rafelo::Core::PageProps
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
              customerName: @order.customer_name,
              status: @order.status,
              version: @order.version
            },
            updatePath: context.urls.route(:example_orders, :order, id: @order.id),
            showPath: context.urls.route(:example_orders, :order, id: @order.id)
          },
          meta: { formToken: Rafelo::Core::FormToken.issue(session_id: Rafelo::Core::Current.session&.id) },
          query: {},
          pagination: nil,
          can: {}
        }
      end
    end
  end
end
