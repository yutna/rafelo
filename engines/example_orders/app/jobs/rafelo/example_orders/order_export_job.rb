# frozen_string_literal: true

module Rafelo
  module ExampleOrders
    class OrderExportJob < Rafelo::Core::ExportJob
      queue_as :default

      def perform(session_id, export_id)
        with_viewer_session(session_id) do
          export = Rafelo::Core::Export.readable_format.find(export_id)
          query = Rafelo::Core::ListQuery.from({ per_page: "100" }, sort: %w[number])
          orders = OrdersGateway.new(
            token_provider: Rafelo::Core::Current.token_provider,
            budget: Rafelo::Core::Current.call_budget,
            request_id: Rafelo::Core::Current.request_id,
            trace_id: Rafelo::Core::Current.trace_id
          ).list(query)
          csv = +"number,customer,status,total\n"
          orders.items.each do |order|
            csv << [ order.number, order.customer_name, order.status, order.total_minor ].join(",") << "\n"
          end
          attach!(export, io: StringIO.new(csv), filename: export.filename, content_type: "text/csv")
        end
      end
    end
  end
end
