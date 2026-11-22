import "@testing-library/jest-dom/vitest";
import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";

import { ErrorShowScreen } from "./show_screen";

describe("ErrorShowScreen", () => {
  it("shows the code, message, and trace ids", () => {
    render(
      <ErrorShowScreen
        code="not_found"
        message="The page does not exist."
        requestId="request-1"
        traceId="trace-1"
        retryable={false}
      />,
    );

    expect(screen.getByTestId("errors.code")).toHaveTextContent("not_found");
    expect(screen.getByTestId("errors.message")).toHaveTextContent("The page does not exist.");
    expect(screen.getByTestId("errors.trace")).toHaveTextContent("request-1 · trace-1");
  });
});
