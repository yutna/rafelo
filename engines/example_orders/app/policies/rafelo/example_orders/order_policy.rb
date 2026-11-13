# frozen_string_literal: true

module Rafelo
  module ExampleOrders
    class OrderPolicy < Rafelo::Core::BasePolicy
      def index? = permissions.allows?(Rafelo::ExampleOrders::Permissions::ORDER_READ)
      def show? = index?
      def new? = permissions.allows?(Rafelo::ExampleOrders::Permissions::ORDER_CREATE)
      def create? = new?
      def edit? = permissions.allows?(Rafelo::ExampleOrders::Permissions::ORDER_UPDATE)
      def update? = edit?
      def export? = permissions.allows?(Rafelo::ExampleOrders::Permissions::ORDER_EXPORT)
    end
  end
end
