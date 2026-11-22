import type { ReactNode } from "react";

import { sharedPropsSchema } from "@core/contracts/page_props.schema";
import { Icon, isIconName } from "@design_system/icon";
import { Link } from "@design_system/link";
import { usePage } from "@inertiajs/react";

import { t } from "@/lib/i18n";

export function AppShell({ children }: { children: ReactNode }) {
  const { app, nav } = sharedPropsSchema.parse(usePage().props);

  return (
    <div className="min-h-screen">
      <header className="border-b border-slate-200 bg-white">
        <div className="mx-auto flex max-w-5xl flex-wrap items-center justify-between gap-4 px-6 py-3">
          <span className="font-semibold">{app.name}</span>
          <nav aria-label={t("app:nav.label")} className="flex flex-wrap gap-4">
            {nav.map((item) => (
              <Link
                key={item.key}
                testId={`app.nav.${item.key}.link`}
                href={item.path}
                className="inline-flex items-center gap-2 rounded-card px-1 py-1 outline-offset-2 hover:underline focus-visible:outline-2"
              >
                <Icon name={isIconName(item.icon) ? item.icon : "folder"} />
                <span
                  data-testid={`app.nav.${item.key}`}
                  aria-current={item.current ? "page" : undefined}
                  className={item.current ? "font-semibold underline" : undefined}
                >
                  {item.label}
                </span>
              </Link>
            ))}
          </nav>
          <nav aria-label={t("app:locale.label")} className="flex gap-2">
            {app.localeHrefs.map((entry) => (
              <Link
                key={entry.locale}
                testId={`app.locale.${entry.locale}.link`}
                href={entry.href}
                className="rounded-card px-2 py-1 uppercase outline-offset-2 hover:underline focus-visible:outline-2"
              >
                <span
                  data-testid={`app.locale.${entry.locale}`}
                  aria-current={entry.locale === app.locale ? "true" : undefined}
                  className={entry.locale === app.locale ? "font-semibold" : undefined}
                >
                  {entry.locale}
                </span>
              </Link>
            ))}
          </nav>
        </div>
      </header>
      <main id="main-content" tabIndex={-1} data-testid="app.main">
        {children}
      </main>
    </div>
  );
}
