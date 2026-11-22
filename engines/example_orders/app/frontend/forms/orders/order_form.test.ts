import { describe, expect, it } from "vitest";

import { initialOrderForm, orderFormPayload } from "./order_form";

describe("order form", () => {
  it("starts empty for a create and copies an edit", () => {
    expect(initialOrderForm()).toEqual({ customerName: "", status: "open" });
    expect(initialOrderForm({ customerName: "Ada", status: "paid" })).toEqual({
      customerName: "Ada",
      status: "paid",
    });
  });

  it("adds the edit version only when the form has one", () => {
    const values = { customerName: "Ada", status: "paid" };

    expect(orderFormPayload(values)).toEqual({ customerName: "Ada", status: "paid" });
    expect(orderFormPayload(values, 3)).toEqual({
      customerName: "Ada",
      status: "paid",
      version: 3,
    });
  });
});
