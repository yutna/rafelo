import { Head } from "@inertiajs/react";
import type { LayoutName } from "@core/contracts/layout.types";

import { useOrdersTranslation } from "../../i18n";
import { OrdersNewScreen } from "../../screens/orders/new_screen";
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
