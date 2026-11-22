import "@testing-library/jest-dom/vitest";
import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";

import { OrdersList } from "./list";

const order = {
  id: "order-1",
  number: "ORD-1",
  customer: { id: "customer-1", name: "Ada", tier: "gold" },
  status: "open",
  total: { minor: 129900, currency: "USD", exponent: 2 },
  issuedOn: "2026-01-01",
  href: "/en/example_orders/orders/order-1",
};

describe("OrdersList", () => {
  it("renders the order row and its links", () => {
    render(<OrdersList items={[order]} emptyLabel="No orders yet." />);

    expect(screen.getByTestId("example_orders.orders.index.list")).toBeVisible();
    expect(screen.getByTestId("example_orders.orders.index.row.order-1")).toHaveTextContent(
      "ORD-1 · Ada",
    );
    expect(screen.getByTestId("example_orders.orders.index.row.order-1.link")).toHaveAttribute(
      "href",
      order.href,
    );
  });

  it("renders the translated empty state", () => {
    render(<OrdersList items={[]} emptyLabel="No orders yet." />);

    expect(screen.getByTestId("example_orders.orders.index.empty")).toHaveTextContent(
      "No orders yet.",
    );
  });
});
