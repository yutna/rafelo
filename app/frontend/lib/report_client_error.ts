import type { ErrorInfo } from "react";

const MESSAGE_LIMIT = 1_000;
const STACK_LIMIT = 4_000;
export const FIXED_MESSAGE = "An unexpected error occurred.";

type Trace = { requestId?: string; traceId?: string };
type PageContext = { page?: string; release?: string; trace?: Trace };

let currentPage: PageContext = {};

export function setPageContext(context: PageContext): void {
  currentPage = context;
}

function csrfToken(): string | undefined {
  const match = document.cookie
    .split("; ")
    .find((entry) => entry.startsWith("XSRF-TOKEN="));
  if (!match) return undefined;

  const value = match.slice("XSRF-TOKEN=".length);
  try {
    return decodeURIComponent(value);
  } catch {
    return value;
  }
}

function send(payload: {
  message: string;
  stack?: string;
  requestId?: string;
  traceId?: string;
}): void {
  const token = csrfToken();
  void fetch("/core/client_errors", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      ...(token ? { "X-CSRF-Token": token } : {}),
    },
    body: JSON.stringify({
      ...payload,
      page: currentPage.page,
      path: window.location.pathname,
      release: currentPage.release,
      requestId: payload.requestId ?? currentPage.trace?.requestId,
      traceId: payload.traceId ?? currentPage.trace?.traceId,
    }),
    keepalive: true,
  })
    .then((response) => {
      if (!response.ok) console.error("client error report failed");
    })
    .catch(() => console.error("client error report failed"));
}

export function reportClientError(error: Error, info: ErrorInfo, context: Trace): void {
  send({
    message: error.message.slice(0, MESSAGE_LIMIT),
    stack: (info.componentStack ?? error.stack ?? "").slice(0, STACK_LIMIT),
    requestId: context.requestId,
    traceId: context.traceId,
  });
}

export function reportUncaughtError(reason: unknown): void {
  if (reason instanceof Error) {
    send({ message: reason.message.slice(0, MESSAGE_LIMIT), stack: reason.stack?.slice(0, STACK_LIMIT) });
    return;
  }

  send({ message: FIXED_MESSAGE });
}

export function installGlobalErrorReporting(): void {
  window.addEventListener("unhandledrejection", (event) => {
    reportUncaughtError(event.reason);
  });
  window.addEventListener("error", (event) => {
    reportUncaughtError(event.error ?? new Error(FIXED_MESSAGE));
  });
}
