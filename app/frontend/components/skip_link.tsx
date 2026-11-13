import { t } from "../lib/i18n";

export function SkipLink() {
  return (
    <a href="#main-content" className="sr-only focus:not-sr-only focus:fixed focus:left-4 focus:top-4 focus:z-50 focus:rounded-card focus:bg-surface focus:px-4 focus:py-2">
      {t("app:skip")}
    </a>
  );
}
