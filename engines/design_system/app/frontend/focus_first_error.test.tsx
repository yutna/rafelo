import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";

import { focusFirstError } from "./focus_first_error";

describe("focusFirstError", () => {
  it("focuses the summary when only a base error exists", () => {
    render(
      <div data-testid="scope">
        <button type="button" data-testid="summary" data-error-summary tabIndex={-1}>
          Something failed
        </button>
      </div>,
    );

    focusFirstError(screen.getByTestId("scope"));

    expect(screen.getByTestId("summary")).toHaveFocus();
  });

  it("prefers the first invalid field when a base error and field errors exist", () => {
    render(
      <div data-testid="scope">
        <button type="button" data-testid="summary" data-error-summary tabIndex={-1}>
          Something failed
        </button>
        <input data-testid="field" aria-invalid="true" />
      </div>,
    );

    focusFirstError(screen.getByTestId("scope"));

    expect(screen.getByTestId("field")).toHaveFocus();
  });

  it("focuses the first invalid field in DOM order", () => {
    render(
      <div data-testid="scope">
        <input data-testid="first" aria-invalid="true" />
        <input data-testid="second" aria-invalid="true" />
      </div>,
    );

    focusFirstError(screen.getByTestId("scope"));

    expect(screen.getByTestId("first")).toHaveFocus();
  });
});
