import type { LayoutName } from "@core/contracts/layout.types";

import { OrderShowScreen } from "@example_orders/screens/orders/show_screen";
import { Head } from "@inertiajs/react";

import { pageSchema } from "./show.schema";

export default function OrderShow(props: Record<string, unknown>) {
  const page = pageSchema.parse(props);
  return (
    <>
      <Head title={page.data.order.number} />
      <OrderShowScreen {...page.data} can={page.can} />
    </>
  );
}

OrderShow.layoutName = "app" satisfies LayoutName;
