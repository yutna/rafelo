import { render, screen } from "@testing-library/react";
import { afterEach, describe, expect, it, vi } from "vitest";

const reporter = vi.hoisted(() => vi.fn());

vi.mock("./report_client_error", () => ({ reportClientError: reporter }));

import { RootBoundary } from "./root_boundary";

function Broken(): never {
  throw new Error("boom");
}

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

    const alert = screen.getByTestId("app.root_error");
    expect(alert).toHaveTextContent("request-1");
    expect(reporter).toHaveBeenCalledTimes(1);
  });

  it("resets the boundary when the page URL changes", () => {
    vi.spyOn(console, "error").mockImplementation(() => {});

    const { rerender } = render(
      <RootBoundary pageUrl="/en">
        <Broken />
      </RootBoundary>,
    );
    expect(screen.getByTestId("app.root_error")).toBeVisible();

    rerender(
      <RootBoundary pageUrl="/en/orders">
        <p data-testid="recovered">Recovered</p>
      </RootBoundary>,
    );

    expect(screen.getByTestId("recovered")).toBeVisible();
    expect(screen.queryByTestId("app.root_error")).not.toBeInTheDocument();
  });
});
