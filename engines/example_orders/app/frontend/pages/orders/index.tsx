import { Head } from "@inertiajs/react";
import type { LayoutName } from "@core/contracts/layout.types";

import { t } from "../../i18n";
import { OrdersScreen } from "../../screens/orders/index_screen";
import { pageSchema } from "./index.schema";

export default function OrdersIndex(props: Record<string, unknown>) {
  const page = pageSchema.parse(props);
  return (
    <>
      <Head title={t("orders.title")} />
      <OrdersScreen {...page.data} can={page.can} meta={page.meta} />
    </>
  );
}

OrdersIndex.layoutName = "app" satisfies LayoutName;
