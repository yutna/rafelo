import { describe, expect, it } from "vitest";

import { DateRange } from "./date_range";

describe("DateRange", () => {
  it("round-trips its plain form", () => {
    const range = DateRange.of("2026-11-01", "2026-11-30");
    expect(DateRange.fromPlain(range.toPlain()).toPlain()).toEqual(range.toPlain());
  });

  it("reports invalid input and impossible dates as issues instead of throwing", () => {
    expect(DateRange.fromPlain({ start: "not-a-date", end: "also-bad" }).issues()).toEqual([
      "date_range.start_invalid",
      "date_range.end_invalid",
    ]);
    expect(DateRange.fromPlain({ start: "2026-02-31", end: "2026-03-01" }).issues()).toEqual([
      "date_range.start_invalid",
    ]);
  });

  it("reports a reversed range and contains ISO dates only when ordered", () => {
    const reversed = DateRange.of("2026-11-12", "2026-11-11");
    expect(reversed.issues()).toEqual([ "date_range.end_before_start" ]);
    expect(reversed.contains("2026-11-11")).toBe(false);
  });
});
