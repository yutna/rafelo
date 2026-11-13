import type { ErrorInfo } from "react";

export function reportClientError(error: Error, info: ErrorInfo, context: { requestId?: string; traceId?: string }) {
  const token = document.querySelector<HTMLMetaElement>('meta[name="csrf-token"]')?.content;
  void fetch("/core/client_errors", {
    method: "POST",
    headers: { "Content-Type": "application/json", ...(token ? { "X-CSRF-Token": token } : {}) },
    body: JSON.stringify({
      message: error.message.slice(0, 1000),
      componentStack: info.componentStack?.slice(0, 4000),
      requestId: context.requestId,
      traceId: context.traceId,
      path: window.location.pathname,
    }),
  });
}
