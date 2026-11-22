import { Head } from "@inertiajs/react";

import type { LayoutName } from "@/lib/layout_name";

import { t } from "@/lib/i18n";
import { HomeScreen } from "@/screens/home/home_screen";

import { pageSchema } from "./index.schema";

export default function HomeIndex(props: Record<string, unknown>) {
  const page = pageSchema.parse(props);

  return (
    <>
      <Head title={t("app:home.message")} />
      <HomeScreen message={page.data.message} />
    </>
  );
}

HomeIndex.layoutName = "app" satisfies LayoutName;
