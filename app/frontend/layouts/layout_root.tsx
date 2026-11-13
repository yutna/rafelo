import { usePage } from "@inertiajs/react";
import type { ReactNode } from "react";

import { I18nProvider } from "@design_system/i18n_provider";

import { FlashStatus } from "./flash_status";
import { PageAnnouncer } from "./page_announcer";
import { SkipLink } from "../components/skip_link";

type LayoutRootProps = {
  children: ReactNode;
};

export function LayoutRoot({ children }: LayoutRootProps) {
  const page = usePage().props as { app?: { locale?: string; timeZone?: string } };
  const locale = page.app?.locale ?? "en";
  const timeZone = page.app?.timeZone ?? "UTC";

  return (
    <I18nProvider locale={locale} timeZone={timeZone}>
      <div lang={locale} data-time-zone={timeZone} data-testid="app-root" className="min-h-screen bg-slate-50 text-slate-900">
        <SkipLink />
        <PageAnnouncer />
        <FlashStatus />
        <main id="main-content" tabIndex={-1}>
          {children}
        </main>
      </div>
    </I18nProvider>
  );
}
