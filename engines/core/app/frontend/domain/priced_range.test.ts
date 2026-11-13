import { describe, expect, it } from "vitest";

import { DateRange } from "./date_range";
import { Money } from "./money";
import { PricedRange } from "./priced_range";

describe("PricedRange", () => {
  it("composes a range and a rate without inheritance", () => {
    const priced = PricedRange.of(DateRange.of("2026-11-01", "2026-11-30"), Money.of(500, "THB"));
    expect(priced.total(3).minor).toBe(1500);
    expect(PricedRange.fromPlain(priced.toPlain()).toPlain()).toEqual(priced.toPlain());
  });
});
