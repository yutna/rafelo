import { Head } from "@inertiajs/react";

import type { LayoutName } from "../../lib/layout_name";
import { pageSchema } from "./show.schema";

export default function ErrorShow(props: Record<string, unknown>) {
  const page = pageSchema.parse(props);

  return (
    <main className="mx-auto max-w-2xl px-6 py-24">
      <Head title="Error" />
      <p className="text-sm font-medium uppercase tracking-wider text-slate-500">
        {page.data.code}
      </p>
      <h1 className="mt-4 text-3xl font-semibold tracking-tight text-slate-900">
        {page.data.message}
      </h1>
      <p className="mt-4 text-sm text-slate-600">
        {page.data.requestId} · {page.data.traceId}
      </p>
    </main>
  );
}

ErrorShow.layoutName = "bare" satisfies LayoutName;
