import type { LayoutName } from "@core/contracts/layout.types";

import { useOrdersTranslation } from "@example_orders/i18n";
import { OrdersNewScreen } from "@example_orders/screens/orders/new_screen";
import { Head } from "@inertiajs/react";

import { pageSchema } from "./new.schema";

export default function OrdersNew(props: Record<string, unknown>) {
  const t = useOrdersTranslation();
  const page = pageSchema.parse(props);
  return (
    <>
      <Head title={t("orders.new")} />
      <OrdersNewScreen {...page.data} meta={page.meta} errors={page.errors} />
    </>
  );
}

OrdersNew.layoutName = "app" satisfies LayoutName;
