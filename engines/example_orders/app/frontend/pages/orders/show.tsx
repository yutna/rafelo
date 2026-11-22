import type { LayoutName } from "@core/contracts/layout.types";

import { useOrdersTranslation } from "@example_orders/i18n";
import { OrderShowScreen } from "@example_orders/screens/orders/show_screen";
import { Head } from "@inertiajs/react";

import { pageSchema } from "./show.schema";

export default function OrderShow(props: Record<string, unknown>) {
  const t = useOrdersTranslation();
  const page = pageSchema.parse(props);
  return (
    <>
      <Head title={t("orders.show_title", { number: page.data.order.number })} />
      <OrderShowScreen {...page.data} can={page.can} />
    </>
  );
}

OrderShow.layoutName = "app" satisfies LayoutName;
