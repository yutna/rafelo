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
  useForm: () => ({
    data: { email: "", password: "" },
    errors: {},
    post: vi.fn(),
    processing: false,
    setData: vi.fn(),
  }),
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

function signInProps(locale: "en" | "th") {
  return {
    ...shared,
    app: { ...shared.app, locale },
    data: { error: null, formHref: "/en/sign_in" },
    meta: { csrfToken: "token" },
    query: {},
    pagination: null,
    can: {},
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

  it("renders a page in English and then in Thai after a fresh Inertia mount", async () => {
    const EnglishPage = await resolvePage("sessions/new", {
      props: { app: { locale: "en" } },
    });
    const { rerender } = render(<EnglishPage {...signInProps("en")} />);
    expect(screen.getByRole("heading", { level: 1 })).toHaveTextContent("Sign in");

    const ThaiPage = await resolvePage("sessions/new", {
      props: { app: { locale: "th" } },
    });
    rerender(<ThaiPage key="th" {...signInProps("th")} />);

    expect(screen.getByRole("heading", { level: 1 })).toHaveTextContent("เข้าสู่ระบบ");
  });

  it("fails when the page's locale has no catalog", async () => {
    await expect(resolvePage("sessions/new", { props: { app: { locale: "fr" } } })).rejects.toThrow(
      "Missing app catalog for fr",
    );
  });
});
