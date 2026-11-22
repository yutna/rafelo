import { OrdersNewContainer } from "@example_orders/containers/orders/new_container";

export function OrdersNewScreen(props: Parameters<typeof OrdersNewContainer>[0]) {
  return <OrdersNewContainer {...props} />;
}
