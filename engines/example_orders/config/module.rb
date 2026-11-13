# frozen_string_literal: true

Rafelo::Core::Modules.register(
  key: :example_orders,
  engine: Rafelo::ExampleOrders::Engine,
  path: "/example_orders",
  permission_prefixes: [ "example_orders" ],
  nav: { order: 20, label_key: "example_orders.nav.title", icon: "receipt" }
)
