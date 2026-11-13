import { OrdersNewScreen } from "../../screens/orders/new_screen";

export function OrdersNewContainer(
  props: Parameters<typeof OrdersNewScreen>[0],
) {
  return <OrdersNewScreen {...props} />;
}
