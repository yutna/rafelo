import type { ReactNode } from "react";

import { ErrorBoundary } from "@design_system/error_boundary";
import { z } from "zod";

import { t } from "./i18n";
import { reportClientError } from "./report_client_error";

const traceSchema = z.object({ requestId: z.string(), traceId: z.string() });

export function RootBoundary({
  children,
  pageUrl,
  trace,
}: {
  children: ReactNode;
  pageUrl: string;
  trace?: unknown;
}) {
  const parsedTrace = traceSchema.safeParse(trace);

  return (
    <ErrorBoundary
      testId="app.root_error"
      title={t("app:errors.page_title")}
      homeLabel={t("app:errors.go_home")}
      retryLabel={t("app:errors.retry")}
      homeHref="/"
      resetKey={pageUrl}
      requestId={parsedTrace.success ? parsedTrace.data.requestId : undefined}
      traceId={parsedTrace.success ? parsedTrace.data.traceId : undefined}
      reporter={reportClientError}
    >
      {children}
    </ErrorBoundary>
  );
}
