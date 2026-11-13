import { render, screen } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";

import { PageErrorBoundary } from "./page_error_boundary";

function Boom(): never {
  throw new Error("boom");
}

describe("PageErrorBoundary", () => {
  it("keeps a fallback in place when a page throws", () => {
    vi.stubGlobal("fetch", vi.fn());
    vi.spyOn(console, "error").mockImplementation(() => {});

    render(
      <PageErrorBoundary>
        <Boom />
      </PageErrorBoundary>,
    );

    expect(screen.getByRole("alert")).toHaveTextContent("Something went wrong.");
  });
});
