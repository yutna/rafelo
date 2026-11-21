import type { ReactNode } from "react";

import { sharedPropsSchema } from "@core/contracts/page_props.schema";
import { I18nProvider } from "@design_system/i18n_provider";
import { usePage } from "@inertiajs/react";

import { SkipLink } from "@/components/skip_link";

import { FlashStatus } from "./flash_status";
import { PageAnnouncer } from "./page_announcer";

type LayoutRootProps = {
  children: ReactNode;
};

export function LayoutRoot({ children }: LayoutRootProps) {
  const { app } = sharedPropsSchema.parse(usePage().props);

  return (
    <I18nProvider locale={app.locale} timeZone={app.timeZone}>
      <div
        lang={app.locale}
        data-time-zone={app.timeZone}
        data-testid="app-root"
        className="min-h-screen bg-slate-50 text-slate-900"
      >
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
