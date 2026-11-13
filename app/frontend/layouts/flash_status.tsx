import { usePage } from "@inertiajs/react";

export function FlashStatus() {
  const page = usePage() as { flash?: { notice?: string; alert?: string } };
  const notice = page.flash?.notice;
  const alert = page.flash?.alert;

  if (!notice && !alert) return null;

  return (
    <div role={alert ? "alert" : "status"} aria-live={alert ? "assertive" : "polite"} data-testid="flash-status" className="mx-auto max-w-3xl px-6 pt-4">
      {alert ?? notice}
    </div>
  );
}
