import { render, screen } from "@testing-library/react";
import { afterEach, describe, expect, it, vi } from "vitest";

const reporter = vi.hoisted(() => vi.fn());
const inertia = vi.hoisted(() => ({ props: {} as Record<string, unknown> }));

vi.mock("./report_client_error", () => ({ reportClientError: reporter }));
vi.mock("@inertiajs/react", () => ({
  usePage: () => ({ flash: {}, props: inertia.props, url: "/en" }),
}));

import { LayoutRoot } from "@/layouts/layout_root";

import { RootBoundary } from "./root_boundary";

function Broken(): never {
  throw new Error("boom");
}

function BrokenShell(): never {
  throw new Error("shell boom");
}

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

describe("RootBoundary", () => {
  afterEach(() => {
    reporter.mockClear();
    vi.restoreAllMocks();
  });

  it("renders the shared error state and reports a shell failure", () => {
    vi.spyOn(console, "error").mockImplementation(() => {});

    render(
      <RootBoundary pageUrl="/en" trace={{ requestId: "request-1", traceId: "trace-1" }}>
        <Broken />
      </RootBoundary>,
    );

    const alert = screen.getByRole("alert");
    expect(alert).toHaveTextContent("request-1");
    expect(reporter).toHaveBeenCalledTimes(1);
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
});
