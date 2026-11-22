import { Head } from "@inertiajs/react";

import type { LayoutName } from "@/lib/layout_name";

import { t } from "@/lib/i18n";

import { pageSchema } from "./show.schema";

export default function ErrorShow(props: Record<string, unknown>) {
  const page = pageSchema.parse(props);

  return (
    <section className="mx-auto max-w-2xl px-6 py-24">
      <Head title={t("app:errors.page_title")} />
      <p className="text-sm font-medium tracking-wider text-slate-500 uppercase">
        {page.data.code}
      </p>
      <h1 className="mt-4 text-3xl font-semibold tracking-tight text-slate-900">
        {page.data.message}
      </h1>
      <p className="mt-4 text-sm text-slate-600">
        {page.data.requestId} · {page.data.traceId}
      </p>
    </section>
  );
}

ErrorShow.layoutName = "bare" satisfies LayoutName;
