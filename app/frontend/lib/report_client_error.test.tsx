import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import type { ErrorInfo } from "react";

import {
  FIXED_MESSAGE,
  installGlobalErrorReporting,
  reportClientError,
  setPageContext,
} from "./report_client_error";

function fetchMock() {
  return vi.fn().mockResolvedValue({ ok: true });
}

function sentBody(call = 0): Record<string, unknown> {
  const mock = globalThis.fetch as unknown as ReturnType<typeof vi.fn>;
  return JSON.parse(mock.mock.calls[call][1].body as string);
}

async function flush(): Promise<void> {
  await Promise.resolve();
  await Promise.resolve();
}

describe("reportClientError", () => {
  let fetch: ReturnType<typeof vi.fn>;

  beforeEach(() => {
    fetch = fetchMock();
    vi.stubGlobal("fetch", fetch);
    setPageContext({
      page: "orders/index",
      release: "a".repeat(40),
      trace: { requestId: "request-1", traceId: "b".repeat(32) },
    });
    document.cookie = "XSRF-TOKEN=token-1; path=/";
  });

  afterEach(() => {
    vi.unstubAllGlobals();
    vi.restoreAllMocks();
    document.cookie = "XSRF-TOKEN=; expires=Thu, 01 Jan 1970 00:00:00 GMT; path=/";
  });

  it("reads the XSRF cookie at send time", async () => {
    reportClientError(new Error("boom"), { componentStack: "at Page" } as ErrorInfo, {});
    await flush();

    expect(fetch.mock.calls[0][1].headers["X-CSRF-Token"]).toBe("token-1");

    document.cookie = "XSRF-TOKEN=token-2; path=/";
    reportClientError(new Error("again"), { componentStack: "at Page" } as ErrorInfo, {});
    await flush();

    expect(fetch.mock.calls[1][1].headers["X-CSRF-Token"]).toBe("token-2");
  });

  it("bounds the message and stack and sends keepalive", async () => {
    const long = "a".repeat(50_000);
    reportClientError(new Error(long), { componentStack: long } as ErrorInfo, {
      requestId: "request-1",
      traceId: "b".repeat(32),
    });
    await flush();

    const body = sentBody();
    expect((body.message as string).length).toBe(1_000);
    expect((body.stack as string).length).toBe(4_000);
    expect(JSON.stringify(body).length).toBeLessThan(8 * 1024);
    expect(fetch.mock.calls[0][1].keepalive).toBe(true);
    expect(body.path).toBe(window.location.pathname);
    expect(body.release).toBe("a".repeat(40));
  });

  it("logs a failed report once and does not retry", async () => {
    fetch.mockResolvedValue({ ok: false });
    const consoleError = vi.spyOn(console, "error").mockImplementation(() => undefined);

    reportClientError(new Error("boom"), { componentStack: "" } as ErrorInfo, {});
    await flush();

    expect(consoleError).toHaveBeenCalledTimes(1);
    expect(fetch).toHaveBeenCalledTimes(1);
  });

  it("reports a window error and a non-Error rejection with the fixed message", async () => {
    installGlobalErrorReporting();

    window.dispatchEvent(new ErrorEvent("error", { error: new Error("window boom") }));
    await flush();
    expect(fetch).toHaveBeenCalledTimes(1);
    expect(sentBody(0).message).toBe("window boom");

    const rejection = new Event("unhandledrejection") as Event & { reason?: unknown };
    rejection.reason = { secret: "not-an-error" };
    window.dispatchEvent(rejection);
    await flush();

    expect(fetch).toHaveBeenCalledTimes(2);
    const body = sentBody(1);
    expect(body.message).toBe(FIXED_MESSAGE);
    expect(body).not.toHaveProperty("stack");
    expect(JSON.stringify(body)).not.toContain("not-an-error");
  });
});
