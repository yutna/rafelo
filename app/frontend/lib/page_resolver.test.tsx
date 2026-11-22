import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { afterEach, describe, expect, it, vi } from "vitest";

const inertia = vi.hoisted(() => ({
  props: {} as Record<string, unknown>,
  url: "/en/invoices/1",
}));
const reporter = vi.hoisted(() => vi.fn());

vi.mock("@inertiajs/react", async (importOriginal) => ({
  ...(await importOriginal<typeof import("@inertiajs/react")>()),
  Head: () => null,
  usePage: () => ({ flash: {}, props: inertia.props, url: inertia.url }),
}));
vi.mock("./report_client_error", async (importOriginal) => {
  const actual = await importOriginal<typeof import("./report_client_error")>();
  return { ...actual, reportClientError: reporter };
});

import { t } from "./i18n";
import { resolvePage } from "./page_resolver";

const shared = {
  auth: { viewer: null },
  trace: { requestId: "request-1", traceId: "trace-1" },
  app: {
    name: "Rafelo",
    locale: "en",
    locales: ["en", "th"],
    localeHrefs: [
      { locale: "en", href: "/en" },
      { locale: "th", href: "/th" },
    ],
    signInHref: "/en/sign_in",
    timeZone: "Asia/Bangkok",
  },
  nav: [],
  errors: {},
};

const validErrorProps = {
  ...shared,
  data: {
    code: "not_found",
    message: "The page does not exist.",
    requestId: "request-1",
    traceId: "trace-1",
    retryable: false,
  },
  meta: {},
  query: {},
  pagination: null,
  can: {},
};

describe("resolvePage", () => {
  afterEach(() => {
    reporter.mockClear();
    vi.restoreAllMocks();
    inertia.url = "/en/invoices/1";
  });

  it("resolves one page name to one component identity", async () => {
    const first = await resolvePage("errors/show", { props: shared });
    const second = await resolvePage("errors/show", { props: shared });

    expect(first).toBe(second);
  });

  it("rejects a page name it does not know", async () => {
    await expect(resolvePage("missing/page", { props: shared })).rejects.toThrow(
      "Page not found: missing/page",
    );
  });

  it("reports a throwing page with the trace and resets on the next page URL", async () => {
    vi.spyOn(console, "error").mockImplementation(() => {});
    inertia.url = "/en/invoices/1";

    const Page = await resolvePage("errors/show", { props: shared });
    const { rerender } = render(<Page {...shared} />);

    expect(screen.getByTestId("page.error")).toBeVisible();
    expect(reporter).toHaveBeenCalledTimes(1);
    expect(reporter).toHaveBeenCalledWith(expect.any(Error), expect.anything(), {
      requestId: "request-1",
      traceId: "trace-1",
    });

    inertia.url = "/en/invoices/2";
    rerender(<Page {...validErrorProps} />);

    expect(screen.queryByTestId("page.error")).not.toBeInTheDocument();
    expect(screen.getByRole("heading", { level: 1 })).toHaveTextContent("The page does not exist.");
  });

  it("clears the error and renders the page again after a retry", async () => {
    vi.spyOn(console, "error").mockImplementation(() => {});

    const Page = await resolvePage("errors/show", { props: shared });
    const { rerender } = render(<Page />);
    expect(screen.getByTestId("page.error")).toBeVisible();

    rerender(<Page {...validErrorProps} />);
    expect(screen.getByTestId("page.error")).toBeVisible();

    await userEvent.click(screen.getByRole("button", { name: t("app:errors.retry") }));

    expect(screen.queryByTestId("page.error")).not.toBeInTheDocument();
    expect(screen.getByRole("heading", { level: 1 })).toHaveTextContent("The page does not exist.");
  });
});
