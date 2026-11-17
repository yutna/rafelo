import "@testing-library/jest-dom/vitest";
import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";

import { HiddenField } from "./hidden_field";

describe("HiddenField", () => {
  it("renders a hidden input with its name and value", () => {
    render(<HiddenField testId="signin.csrf" name="authenticity_token" value="token" />);

    const input = screen.getByTestId("signin.csrf");
    expect(input).toHaveAttribute("type", "hidden");
    expect(input).toHaveAttribute("name", "authenticity_token");
    expect(input).toHaveValue("token");
  });
});
