# frozen_string_literal: true

module Rafelo
  module ExampleCustomers
    # Public value object: other engines may use this without reaching into
    # example_customers' private models (ARCH-05, ARCH-09).
    Customer = Data.define(:id, :name, :tier)
  end
end
