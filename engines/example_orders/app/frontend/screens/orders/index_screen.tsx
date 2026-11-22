import { OrdersIndexContainer } from "@example_orders/containers/orders/index_container";

export function OrdersScreen(props: Parameters<typeof OrdersIndexContainer>[0]) {
  return <OrdersIndexContainer {...props} />;
}
