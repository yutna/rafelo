import { describe, expect, it } from "vitest";

import { DateRange } from "./date_range";

describe("DateRange", () => {
  it("reports a reversed range as an issue instead of throwing", () => {
    const range = DateRange.of("2026-11-12", "2026-11-11");
    expect(range.issues()).toEqual([ "date_range.end_before_start" ]);
  });

  it("contains ISO dates inside an ordered range", () => {
    const range = DateRange.of("2026-11-01", "2026-11-30");
    expect(range.contains("2026-11-11")).toBe(true);
    expect(range.contains("2026-12-01")).toBe(false);
  });
});
