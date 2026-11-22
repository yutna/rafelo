import { Head } from "@inertiajs/react";

import type { LayoutName } from "@/lib/layout_name";

import { t } from "@/lib/i18n";
import { ErrorShowScreen } from "@/screens/errors/show_screen";

import { pageSchema } from "./show.schema";

export default function ErrorShow(props: Record<string, unknown>) {
  const page = pageSchema.parse(props);

  return (
    <>
      <Head title={t("app:errors.page_title")} />
      <ErrorShowScreen {...page.data} />
    </>
  );
}

ErrorShow.layoutName = "bare" satisfies LayoutName;
