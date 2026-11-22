import { Head } from "@inertiajs/react";

import type { LayoutName } from "@/lib/layout_name";

import { t } from "@/lib/i18n";
import { ComponentCatalogScreen } from "@/screens/component_catalog/component_catalog_screen";

import { pageSchema } from "./index.schema";

export default function ComponentCatalogIndex(props: Record<string, unknown>) {
  pageSchema.parse(props);

  return (
    <>
      <Head title={t("app:catalog.title")} />
      <ComponentCatalogScreen />
    </>
  );
}

ComponentCatalogIndex.layoutName = "app" satisfies LayoutName;
