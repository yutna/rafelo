import { usePage } from "@inertiajs/react";

import { flashSchema } from "@core/contracts/page_props.schema";

export function FlashStatus() {
  const page = usePage() as { flash?: unknown };
  const parsed = flashSchema.safeParse(page.flash ?? {});
  const flash = parsed.success ? parsed.data : {};
  const alert = flash.alert;

  return (
    <div role={alert ? "alert" : "status"} aria-live={alert ? "assertive" : "polite"} data-testid="page.flash" className="mx-auto max-w-3xl px-6 pt-4">
      {alert ?? flash.notice ?? ""}
    </div>
  );
}
