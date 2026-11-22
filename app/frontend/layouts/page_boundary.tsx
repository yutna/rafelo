import type { ReactNode } from "react";

import { ErrorBoundary } from "@design_system/error_boundary";
import { usePage } from "@inertiajs/react";

import { t } from "@/lib/i18n";
import { reportClientError } from "@/lib/report_client_error";

export function PageBoundary({ children, trace }: { children: ReactNode; trace?: unknown }) {
  const { url } = usePage();
  const context = trace as { requestId?: string; traceId?: string } | undefined;

  return (
    <ErrorBoundary
      testId="page.error"
      title={t("app:errors.page_title")}
      homeLabel={t("app:errors.go_home")}
      retryLabel={t("app:errors.retry")}
      homeHref="/"
      resetKey={url}
      requestId={context?.requestId}
      traceId={context?.traceId}
      reporter={reportClientError}
    >
      {children}
    </ErrorBoundary>
  );
}
