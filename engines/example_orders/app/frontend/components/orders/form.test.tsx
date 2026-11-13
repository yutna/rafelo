import "@testing-library/jest-dom/vitest";
import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";

import { OrderFormFields } from "./form";

describe("OrderFormFields", () => {
  it("renders the design-system fields and errors", () => {
    render(
      <OrderFormFields
        customerName="Ada"
        status="open"
        errors={{ customerName: "can't be blank" }}
        onCustomerNameChange={() => undefined}
        onStatusChange={() => undefined}
      />,
    );

    expect(screen.getByTestId("example_orders.orders.form.customer")).toHaveValue("Ada");
    expect(screen.getByTestId("example_orders.orders.form.status")).toHaveValue("open");
    expect(screen.getByText("can't be blank")).toBeInTheDocument();
  });

  it("shows a base error after a conflicting update", () => {
    render(
      <OrderFormFields
        customerName="Ada"
        status="open"
        baseError="The order changed since you opened it."
        errors={{}}
        onCustomerNameChange={() => undefined}
        onStatusChange={() => undefined}
      />,
    );

    expect(screen.getByTestId("example_orders.orders.form.base-error")).toHaveTextContent(
      "The order changed since you opened it.",
    );
  });
});
