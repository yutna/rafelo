# frozen_string_literal: true

module Rafelo
  module ExampleOrders
    class OrdersController < Rafelo::Core::BaseController
      layout "application"

      throttle to: 30, within: 1.minute, only: %i[create update export], name: "example_orders/write"

      def index
        authorize :order, :index?, policy_class: OrderPolicy
        query = Rafelo::Core::ListQuery.from(
          params,
          sort: %w[number issued_on total],
          filters: { "status" => %w[open paid cancelled] }
        )
        page = gateway(OrdersGateway).list(query)
        render_page "example_orders/orders/index",
                    props: OrdersIndexProps.new(context: page_context, page: page, query: query)
      end

      def show
        authorize :order, :show?, policy_class: OrderPolicy
        order = gateway(OrdersGateway).find(params[:id])
        render_page "example_orders/orders/show",
                    props: OrdersShowProps.new(context: page_context, order: order)
      end

      def new
        authorize :order, :new?, policy_class: OrderPolicy
        render_page "example_orders/orders/new", props: OrdersNewProps.new(context: page_context)
      end

      def create
        authorize :order, :create?, policy_class: OrderPolicy
        form = OrderForm.new(params.permit(:customer_name, :status, :token))
        back = page_context.urls.route(:example_orders, :new_order)
        return redirect_after_write(back, errors: form.error_messages) if form.invalid?

        Rafelo::Core::IdempotencyClaim.call(self, token: form.token, payload: form.payload, back: back) do |idempotency_key|
          order = gateway(OrdersGateway).create(payload: form.payload, idempotency_key: idempotency_key)
          redirect_after_write(
            page_context.urls.route(:example_orders, :order, id: order.id),
            notice: t("example_orders.orders.created", number: order.number)
          )
        end
      rescue Rafelo::Core::ValidationFailed => error
        redirect_after_write(back, errors: form.translate(error.field_codes))
      rescue Rafelo::Core::ApplicationError => error
        raise unless error.code == "resource.conflict"

        redirect_after_write(back, errors: { "base" => I18n.t("example_orders.orders.conflict") })
      end

      def edit
        authorize :order, :edit?, policy_class: OrderPolicy
        order = gateway(OrdersGateway).find(params[:id])
        render_page "example_orders/orders/edit",
                    props: OrdersEditProps.new(context: page_context, order: order)
      end

      def update
        authorize :order, :update?, policy_class: OrderPolicy
        form = OrderForm.new(params.permit(:customer_name, :status, :version, :token))
        back = page_context.urls.route(:example_orders, :edit_order, id: params[:id])
        return redirect_after_write(back, errors: form.error_messages) if form.invalid?

        Rafelo::Core::IdempotencyClaim.call(self, token: form.token, payload: form.payload, back: back) do |idempotency_key|
          order = gateway(OrdersGateway).update(
            id: params[:id],
            payload: form.payload.except(:version),
            idempotency_key: idempotency_key,
            if_match: form.version
          )
          redirect_after_write(
            page_context.urls.route(:example_orders, :order, id: order.id),
            notice: t("example_orders.orders.updated", number: order.number)
          )
        end
      rescue Rafelo::Core::ValidationFailed => error
        redirect_after_write(back, errors: form.translate(error.field_codes))
      rescue Rafelo::Core::ApplicationError => error
        raise unless error.code == "resource.conflict"

        redirect_after_write(back, errors: { "base" => I18n.t("example_orders.orders.conflict") })
      end

      def export
        authorize :order, :export?, policy_class: OrderPolicy
        export = Rafelo::Core::Export.build_for(
          viewer: Rafelo::Core::Current.viewer,
          filename: "orders.csv"
        )
        OrderExportJob.perform_later(Rafelo::Core::Current.session.id, export.id)
        redirect_after_write(
          page_context.urls.route(:example_orders, :orders),
          notice: t("example_orders.orders.export_queued")
        )
      end
    end
  end
end
