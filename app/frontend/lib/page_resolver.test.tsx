import "@testing-library/jest-dom/vitest";
import { render, screen } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";

vi.mock("@inertiajs/react", () => ({
  Deferred: ({ children }: { children: React.ReactNode }) => <>{children}</>,
  Head: () => null,
  Link: ({ href, children }: { href: string; children: React.ReactNode }) => (
    <a href={href}>{children}</a>
  ),
  router: { post: vi.fn() },
}));
vi.mock("@/layouts/page_boundary", () => ({
  PageBoundary: ({ children }: { children: React.ReactNode }) => <>{children}</>,
}));

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

const page = {
  props: {
    app: { locale: "en" },
    trace: { requestId: "request-1", traceId: "trace-1" },
  },
};

function ordersProps(locale: "en" | "th") {
  return {
    ...shared,
    app: { ...shared.app, locale },
    data: {
      items: [],
      newHref: null,
      exportHref: "/en/example_orders/orders/export",
      filterHrefs: [],
      previousHref: null,
      nextHref: null,
    },
    meta: { formToken: "token" },
    query: { page: 1, perPage: 10, sort: null, direction: "asc", filters: {}, cursor: null },
    pagination: { kind: "offset", page: 1, perPage: 10, total: 0, pageCount: 0 },
    can: {
      "order.create": { allowed: false, reason: null },
      "order.export": { allowed: false, reason: null },
    },
  };
}

describe("resolvePage", () => {
  it("resolves one page name to one component identity", async () => {
    const first = await resolvePage("errors/show", page);
    const second = await resolvePage("errors/show", page);

    expect(first).toBe(second);
  });

  it("rejects a page name it does not know", async () => {
    await expect(resolvePage("missing/page", page)).rejects.toThrow("Page not found: missing/page");
  });

  it("wraps an app page in a named layout", async () => {
    const appPage = await resolvePage("home/index", page);

    expect(typeof appPage.layout).toBe("function");
  });

  it("renders a module page in English and then in Thai after a visit", async () => {
    const EnglishPage = await resolvePage("example_orders/orders/index", {
      props: { app: { locale: "en" } },
    });
    const { rerender } = render(<EnglishPage {...ordersProps("en")} />);
    expect(screen.getByRole("heading", { level: 1 })).toHaveTextContent("Orders");

    const ThaiPage = await resolvePage("example_orders/orders/index", {
      props: { app: { locale: "th" } },
    });
    rerender(<ThaiPage {...ordersProps("th")} />);

    expect(screen.getByRole("heading", { level: 1 })).toHaveTextContent("คำสั่งซื้อ");
  });
});
