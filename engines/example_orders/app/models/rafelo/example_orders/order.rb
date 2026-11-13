# frozen_string_literal: true

module Rafelo
  module ExampleOrders
    Order = Data.define(
      :id, :number, :customer_id, :customer_name, :customer_tier,
      :status, :total_minor, :currency, :issued_on, :version
    )

    OrdersPage = Data.define(:items, :total)
  end
end
