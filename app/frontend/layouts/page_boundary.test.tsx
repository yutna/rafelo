import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { afterEach, describe, expect, it, vi } from "vitest";

const inertia = vi.hoisted(() => ({ url: "/en/invoices/1" }));
const reporter = vi.hoisted(() => vi.fn());

vi.mock("@inertiajs/react", async (importOriginal) => ({
  ...(await importOriginal<typeof import("@inertiajs/react")>()),
  usePage: () => ({ flash: {}, props: {}, url: inertia.url }),
}));
vi.mock("@/lib/report_client_error", async (importOriginal) => {
  const actual = await importOriginal<typeof import("@/lib/report_client_error")>();
  return { ...actual, reportClientError: reporter };
});

import { PageBoundary } from "./page_boundary";

const recordHeading = "Invoice 2";

function Broken(): never {
  throw new Error("boom");
}

function Good() {
  return <h1>{recordHeading}</h1>;
}

describe("PageBoundary", () => {
  afterEach(() => {
    inertia.url = "/en/invoices/1";
    reporter.mockClear();
    vi.restoreAllMocks();
  });

  it("reports a throwing page with the trace and resets on the next page URL", () => {
    vi.spyOn(console, "error").mockImplementation(() => {});

    const { rerender } = render(
      <PageBoundary trace={{ requestId: "request-1", traceId: "trace-1" }}>
        <Broken />
      </PageBoundary>,
    );

    expect(screen.getByTestId("page.error")).toHaveTextContent("request-1");
    expect(screen.getByTestId("page.error.retry")).toBeVisible();
    expect(screen.getByTestId("page.error.home")).toHaveAttribute("href", "/");
    expect(screen.getByTestId("page.error.title")).toHaveFocus();
    expect(reporter).toHaveBeenCalledTimes(1);
    expect(reporter).toHaveBeenCalledWith(expect.any(Error), expect.anything(), {
      requestId: "request-1",
      traceId: "trace-1",
    });

    inertia.url = "/en/invoices/2";
    rerender(
      <PageBoundary trace={{ requestId: "request-2", traceId: "trace-2" }}>
        <Good />
      </PageBoundary>,
    );

    expect(screen.queryByTestId("page.error")).not.toBeInTheDocument();
    expect(screen.getByRole("heading", { level: 1, name: recordHeading })).toHaveTextContent(
      recordHeading,
    );
  });

  it("clears the error and renders the page again after a retry", async () => {
    vi.spyOn(console, "error").mockImplementation(() => {});

    const { rerender } = render(
      <PageBoundary>
        <Broken />
      </PageBoundary>,
    );
    expect(screen.getByTestId("page.error")).toBeVisible();

    rerender(
      <PageBoundary>
        <Good />
      </PageBoundary>,
    );
    expect(screen.getByTestId("page.error")).toBeVisible();

    await userEvent.click(screen.getByTestId("page.error.retry"));

    expect(screen.queryByTestId("page.error")).not.toBeInTheDocument();
    expect(screen.getByRole("heading", { level: 1, name: recordHeading })).toHaveTextContent(
      recordHeading,
    );
  });
});
