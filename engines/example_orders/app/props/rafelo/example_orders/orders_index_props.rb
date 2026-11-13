# frozen_string_literal: true

module Rafelo
  module ExampleOrders
    class OrdersIndexProps < Rafelo::Core::PageProps
      policy_class Rafelo::ExampleOrders::OrderPolicy
      capability Rafelo::ExampleOrders::Permissions::ORDER_CREATE, :create?
      capability Rafelo::ExampleOrders::Permissions::ORDER_EXPORT, :export?

      def initialize(context:, page:, query:)
        super(context: context)
        @page = page
        @query = query
      end

      def envelope
        {
          data: {
            items: @page.items.map { |order| row(order) },
            newHref: context.urls.route(:example_orders, :new_order),
            exportPath: context.urls.route(:example_orders, :export_orders, status: @query.filters["status"]),
            filterHrefs: filter_hrefs,
            previousHref: page_href([ @query.page - 1, 1 ].max),
            nextHref: @query.page < page_count ? page_href(@query.page + 1) : nil,
            chart: InertiaRails.defer { chart_data }
          },
          meta: { formToken: Rafelo::Core::FormToken.issue(session_id: Rafelo::Core::Current.session&.id) },
          query: @query.to_h,
          pagination: {
            kind: "offset",
            page: @query.page,
            perPage: @query.per_page,
            total: @page.total,
            pageCount: (@page.total.to_f / @query.per_page).ceil
          },
          can: capabilities(
            Rafelo::ExampleOrders::Permissions::ORDER_CREATE,
            Rafelo::ExampleOrders::Permissions::ORDER_EXPORT
          )
        }
      end

      private

      def row(order)
        {
          id: order.id,
          number: order.number,
          customer: { id: order.customer_id, name: order.customer_name, tier: order.customer_tier },
          status: order.status,
          total: Rafelo::Core::Money.wire(order.total_minor, order.currency),
          issuedOn: order.issued_on,
          href: context.urls.route(:example_orders, :order, id: order.id)
        }
      end

      def filter_hrefs
        [ nil, "open", "paid", "cancelled" ].map do |status|
          {
            label: status ? I18n.t("example_orders.orders.statuses.#{status}") : I18n.t("example_orders.orders.all"),
            href: context.urls.route(:example_orders, :orders, status: status, per_page: @query.per_page, sort: @query.sort, direction: @query.direction),
            current: @query.filters["status"] == status
          }
        end
      end

      def page_href(page)
        context.urls.route(:example_orders, :orders, page: page, status: @query.filters["status"], per_page: @query.per_page, sort: @query.sort, direction: @query.direction)
      end

      def page_count
        [ (@page.total.to_f / @query.per_page).ceil, 1 ].max
      end

      def chart_data
        counts = @page.items.group_by(&:status).transform_values(&:length)
        {
          series: [
            {
              name: I18n.t("example_orders.orders.title"),
              type: "pie",
              data: counts.map { |status, count| { name: I18n.t("example_orders.orders.statuses.#{status}"), value: count } }
            }
          ]
        }
      end
    end
  end
end
