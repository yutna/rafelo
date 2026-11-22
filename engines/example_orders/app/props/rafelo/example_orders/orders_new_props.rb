# frozen_string_literal: true

module Rafelo
  module ExampleOrders
    class OrdersNewProps < Rafelo::Core::PageProps
      def envelope
        {
          data: {
            createHref: context.urls.route(:example_orders, :orders),
            indexHref: context.urls.route(:example_orders, :orders)
          },
          meta: { formToken: Rafelo::Core::FormToken.issue(session_id: @context.session_id) },
          query: {},
          pagination: nil,
          can: {}
        }
      end
    end
  end
end
