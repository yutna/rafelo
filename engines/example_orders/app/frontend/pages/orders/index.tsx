import { Head } from "@inertiajs/react";
import type { LayoutName } from "@core/contracts/layout.types";

import { OrdersScreen } from "../../screens/orders/index_screen";
import { pageSchema } from "./index.schema";

export default function OrdersIndex(props: Record<string, unknown>) {
  const page = pageSchema.parse(props);
  return (
    <>
      <Head title="Orders" />
      <OrdersScreen {...page.data} can={page.can} />
    </>
  );
}

OrdersIndex.layoutName = "app" satisfies LayoutName;
