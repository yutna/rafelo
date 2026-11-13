import { OrderShowScreen } from "../../screens/orders/show_screen";

export function OrderShowContainer(
  props: Parameters<typeof OrderShowScreen>[0],
) {
  return <OrderShowScreen {...props} />;
}
