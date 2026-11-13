# frozen_string_literal: true

module Rafelo
  module ExampleOrders
    class OrderForm < Rafelo::Core::Form
      attribute :customer_name, :string
      attribute :status, :string
      attribute :version, :string

      validates :customer_name, presence: true, length: { maximum: 80 }
      validates :status, inclusion: { in: %w[open paid cancelled] }
    end
  end
end
