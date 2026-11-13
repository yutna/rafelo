import { Head } from "@inertiajs/react";
import type { LayoutName } from "@core/contracts/layout.types";

import { OrdersEditScreen } from "../../screens/orders/edit_screen";
import { pageSchema } from "./edit.schema";

export default function OrderEdit(props: Record<string, unknown>) {
  const page = pageSchema.parse(props);
  return (
    <>
      <Head title={page.data.order.number} />
      <OrdersEditScreen {...page.data} meta={page.meta} errors={page.errors} />
    </>
  );
}

OrderEdit.layoutName = "app" satisfies LayoutName;
