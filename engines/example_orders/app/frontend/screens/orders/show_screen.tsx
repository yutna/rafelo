import { OrderShowContainer } from "@example_orders/containers/orders/show_container";

export function OrderShowScreen(props: Parameters<typeof OrderShowContainer>[0]) {
  return <OrderShowContainer {...props} />;
}
