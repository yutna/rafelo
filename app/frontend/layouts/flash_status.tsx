import { flashSchema } from "@core/contracts/page_props.schema";
import { usePage } from "@inertiajs/react";

export function FlashStatus() {
  const { notice, alert } = flashSchema.parse(usePage().flash ?? {});

  return (
    <div
      role="status"
      aria-live="polite"
      data-testid="page.flash"
      className="mx-auto max-w-3xl px-6 pt-4"
    >
      {alert ? (
        <p role="alert" data-testid="page.flash.alert">
          {alert}
        </p>
      ) : null}
      {notice ? <p data-testid="page.flash.notice">{notice}</p> : null}
    </div>
  );
}
