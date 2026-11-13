import { OrdersScreen } from "../../screens/orders/index_screen";

export function OrdersIndexContainer(
  props: Parameters<typeof OrdersScreen>[0],
) {
  return <OrdersScreen {...props} />;
}
