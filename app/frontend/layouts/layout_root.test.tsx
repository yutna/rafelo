import "@testing-library/jest-dom/vitest";
import { useLocale } from "@design_system/i18n_provider";
import { cleanup, render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { afterEach, describe, expect, it, vi } from "vitest";

const inertia = vi.hoisted(() => ({
  props: {} as Record<string, unknown>,
}));
const reporter = vi.hoisted(() => vi.fn());

vi.mock("@inertiajs/react", async (importOriginal) => ({
  ...(await importOriginal<typeof import("@inertiajs/react")>()),
  usePage: () => ({ flash: {}, props: inertia.props, url: "/en" }),
}));
vi.mock("@/lib/report_client_error", () => ({ reportClientError: reporter }));

import { RootBoundary } from "@/lib/root_boundary";

import { AppShell } from "./app_shell";
import { AuthShell } from "./auth_shell";
import { BareShell } from "./bare_shell";
import { LayoutRoot } from "./layout_root";

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
  nav: [
    {
      key: "orders",
      label: "Orders",
      path: "/en/example_orders/orders",
      icon: "receipt",
      current: true,
    },
    {
      key: "customers",
      label: "Customers",
      path: "/en/example_customers",
      icon: "folder",
      current: false,
    },
  ],
  errors: {},
};

function BrokenShell(): never {
  throw new Error("shell boom");
}

function LocaleProbe() {
  const { calendar, locale } = useLocale();
  return <span data-testid="locale.probe">{`${locale}:${calendar}`}</span>;
}

describe("LayoutRoot", () => {
  afterEach(() => {
    vi.restoreAllMocks();
  });

  it("parses the shared props and renders the shell", () => {
    inertia.props = shared;

    render(
      <LayoutRoot>
        <h1>Orders</h1>
      </LayoutRoot>,
    );

    expect(screen.getByTestId("app-root")).toHaveAttribute("lang", "en");
    expect(screen.getByTestId("app-root")).toHaveAttribute("data-time-zone", "Asia/Bangkok");
    expect(screen.getByRole("heading", { level: 1 })).toHaveTextContent("Orders");
  });

  it("renders the module nav and locale switcher with their current markers", () => {
    inertia.props = shared;

    render(
      <LayoutRoot>
        <AppShell>
          <h1>Orders</h1>
        </AppShell>
      </LayoutRoot>,
    );

    const current = screen.getByTestId("app.nav.orders");
    expect(current).toHaveAttribute("aria-current", "page");
    expect(current.closest("a")).toHaveAttribute("href", "/en/example_orders/orders");
    expect(current.closest("a")).toContainHTML("<svg");
    expect(screen.getByTestId("app.nav.customers")).not.toHaveAttribute("aria-current");

    expect(screen.getByTestId("app.locale.en")).toHaveAttribute("aria-current", "true");
    expect(screen.getByTestId("app.locale.th").closest("a")).toHaveAttribute("href", "/th");
    expect(screen.getByTestId("app.locale.th")).not.toHaveAttribute("aria-current");
  });

  it("keeps the main-content link first and the main landmark focusable in every shell", async () => {
    inertia.props = shared;

    for (const Shell of [AppShell, AuthShell, BareShell]) {
      render(
        <LayoutRoot>
          <Shell>
            <h1>Page</h1>
          </Shell>
        </LayoutRoot>,
      );

      await userEvent.tab();
      expect(screen.getByTestId("app.main-link")).toHaveFocus();

      const main = screen.getByRole("main");
      expect(main).toHaveAttribute("id", "main-content");
      expect(main).toHaveAttribute("tabindex", "-1");
      main.focus();
      expect(main).toHaveFocus();

      cleanup();
    }
  });

  it("hands the Thai Buddhist calendar to shell widgets", () => {
    inertia.props = { ...shared, app: { ...shared.app, locale: "th" } };

    render(
      <LayoutRoot>
        <LocaleProbe />
      </LayoutRoot>,
    );

    expect(screen.getByTestId("locale.probe")).toHaveTextContent("th:th-TH-u-ca-buddhist");
  });

  it("renders the root error state when a shell throws", () => {
    vi.spyOn(console, "error").mockImplementation(() => {});
    inertia.props = shared;

    render(
      <RootBoundary pageUrl="/en" trace={{ requestId: "request-1", traceId: "trace-1" }}>
        <LayoutRoot>
          <BrokenShell />
        </LayoutRoot>
      </RootBoundary>,
    );

    expect(screen.getByTestId("app.root_error")).toBeVisible();
    expect(screen.getByRole("alert")).toHaveTextContent("request-1");
    expect(screen.getByRole("heading", { level: 1 })).toHaveFocus();
    expect(reporter).toHaveBeenCalledTimes(1);
  });

  it("throws when the shared props do not parse", () => {
    vi.spyOn(console, "error").mockImplementation(() => {});
    inertia.props = { ...shared, app: { ...shared.app, locale: "fr" } };

    expect(() =>
      render(
        <LayoutRoot>
          <h1>Orders</h1>
        </LayoutRoot>,
      ),
    ).toThrow();
  });
});
