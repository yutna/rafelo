import type { LayoutName } from "@core/contracts/layout.types";

import { useOrdersTranslation } from "@example_orders/i18n";
import { OrdersEditScreen } from "@example_orders/screens/orders/edit_screen";
import { Head } from "@inertiajs/react";

import { pageSchema } from "./edit.schema";

export default function OrderEdit(props: Record<string, unknown>) {
  const t = useOrdersTranslation();
  const page = pageSchema.parse(props);
  return (
    <>
      <Head title={t("orders.edit_title", { number: page.data.order.number })} />
      <OrdersEditScreen {...page.data} meta={page.meta} errors={page.errors} />
    </>
  );
}

OrderEdit.layoutName = "app" satisfies LayoutName;
