import { describe, expect, it } from "vitest";

import { ORDER_STATUSES, isOrderStatus } from "./order";

describe("order domain", () => {
  it("recognises only the order statuses the form accepts", () => {
    expect(ORDER_STATUSES).toEqual(["open", "paid", "cancelled"]);
    expect(isOrderStatus("paid")).toBe(true);
    expect(isOrderStatus("refunded")).toBe(false);
  });
});
