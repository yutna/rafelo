# frozen_string_literal: true

module Rafelo
  module ExampleOrders
    class OrderExportJob < Rafelo::Core::ExportJob
      queue_as :default

      def perform(session_id, export_id, status = nil)
        with_viewer_session(session_id) do
          export = Rafelo::Core::Export.readable_format.find(export_id)
          orders = fetch_orders(status.presence)
          attach!(
            export,
            io: StringIO.new(OrdersCsv.render(orders)),
            filename: export.filename,
            content_type: "text/csv"
          )
        end
      end

      private

      def fetch_orders(status)
        query = Rafelo::Core::ListQuery.from({ per_page: "100", status: status }, sort: %w[number])
        gateway = OrdersGateway.new(
          token_provider: Rafelo::Core::Current.token_provider,
          budget: Rafelo::Core::Current.call_budget,
          request_id: Rafelo::Core::Current.request_id,
          trace_id: Rafelo::Core::Current.trace_id
        )
        orders = []
        page = 1
        loop do
          result = gateway.list(query.with(page: page))
          orders.concat(result.items)
          break if result.items.empty? || orders.length >= result.total

          page += 1
        end
        orders
      end
    end
  end
end
