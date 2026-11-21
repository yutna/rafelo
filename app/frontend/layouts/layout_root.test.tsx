import "@testing-library/jest-dom/vitest";
import { useLocale } from "@design_system/i18n_provider";
import { render, screen } from "@testing-library/react";
import { afterEach, describe, expect, it, vi } from "vitest";

const inertia = vi.hoisted(() => ({
  props: {} as Record<string, unknown>,
}));

vi.mock("@inertiajs/react", () => ({
  usePage: () => ({ flash: {}, props: inertia.props, url: "/en" }),
}));

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
  nav: [],
  errors: {},
};

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

  it("hands the Thai Buddhist calendar to shell widgets", () => {
    inertia.props = { ...shared, app: { ...shared.app, locale: "th" } };

    render(
      <LayoutRoot>
        <LocaleProbe />
      </LayoutRoot>,
    );

    expect(screen.getByTestId("locale.probe")).toHaveTextContent("th:th-TH-u-ca-buddhist");
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
