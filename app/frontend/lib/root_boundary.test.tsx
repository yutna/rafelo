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

    const alert = screen.getByRole("alert");
    expect(alert).toHaveTextContent("request-1");
    expect(reporter).toHaveBeenCalledTimes(1);
  });
});
