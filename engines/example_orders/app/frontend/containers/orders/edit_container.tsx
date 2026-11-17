import { OrdersEditScreen } from "@example_orders/screens/orders/edit_screen";

export function OrdersEditContainer(props: Parameters<typeof OrdersEditScreen>[0]) {
  return <OrdersEditScreen {...props} />;
}
