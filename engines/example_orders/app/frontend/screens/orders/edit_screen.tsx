import { OrdersEditContainer } from "@example_orders/containers/orders/edit_container";

export function OrdersEditScreen(props: Parameters<typeof OrdersEditContainer>[0]) {
  return <OrdersEditContainer {...props} />;
}
