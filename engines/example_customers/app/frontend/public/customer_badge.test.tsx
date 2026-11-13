import "@testing-library/jest-dom/vitest";
import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";

import { CustomerBadge } from "./customer_badge";

describe("CustomerBadge", () => {
  it("renders the public customer value", () => {
    render(<CustomerBadge name="Ada" tier="gold" />);

    expect(screen.getByTestId("example_customers.badge")).toHaveTextContent("Ada");
    expect(screen.getByTestId("example_customers.badge")).toHaveTextContent("gold");
  });
});
