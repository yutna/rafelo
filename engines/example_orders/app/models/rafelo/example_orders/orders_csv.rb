# frozen_string_literal: true

module Rafelo
  module ExampleOrders
    # Serializes orders for the export job. Fields are quoted when needed and
    # a leading formula character is neutralized (CSV injection).
    class OrdersCsv
      HEADER = %w[number customer status total_minor].freeze

      def self.render(orders)
        rows = [ HEADER ]
        orders.each { |order| rows << [ order.number, order.customer_name, order.status, order.total_minor ] }
        rows.map { |row| row.map { |value| escape(value) }.join(",") }.join("\n") + "\n"
      end

      def self.escape(value)
        text = value.to_s
        text = "'#{text}" if text.match?(/\A[=+\-@]/)
        return text unless text.include?(",") || text.include?('"') || text.include?("\n") || text.include?("\r")

        "\"#{text.gsub('"', '""')}\""
      end
      private_class_method :escape
    end
  end
end
