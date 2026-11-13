# frozen_string_literal: true

module Rafelo
  module ExampleOrders
    class OrdersNewProps < Rafelo::Core::PageProps
      def envelope
        {
          data: {
            createPath: context.urls.route(:example_orders, :orders),
            indexPath: context.urls.route(:example_orders, :orders)
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
