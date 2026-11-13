import { usePage } from "@inertiajs/react";
import type { ReactNode } from "react";

import { I18nProvider } from "@design_system/i18n_provider";

type LayoutRootProps = {
  children: ReactNode;
};

export function LayoutRoot({ children }: LayoutRootProps) {
  const page = usePage().props as { app?: { locale?: string; timeZone?: string } };
  const locale = page.app?.locale ?? "en";
  const timeZone = page.app?.timeZone ?? "UTC";

  return (
    <I18nProvider locale={locale} timeZone={timeZone}>
      <div lang={locale} data-time-zone={timeZone} className="min-h-screen bg-slate-50 text-slate-900">
        {children}
      </div>
    </I18nProvider>
  );
}
