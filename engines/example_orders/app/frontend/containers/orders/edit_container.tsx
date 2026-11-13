import { OrdersEditScreen } from "../../screens/orders/edit_screen";

export function OrdersEditContainer(
  props: Parameters<typeof OrdersEditScreen>[0],
) {
  return <OrdersEditScreen {...props} />;
}
